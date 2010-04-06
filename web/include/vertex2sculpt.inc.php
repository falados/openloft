<?php
/*	This file is part of OpenLoft.
//
//	OpenLoft is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	OpenLoft is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with OpenLoft.  If not, see <http://www.gnu.org/licenses/>.
//
//	Authors: Falados Kapuskas
*/
require_once('include/openloft_config.inc.php');
require_once('include/gdbundle.inc.php');
require_once('include/vertex.class.inc.php');

defined('OL_INCLUDE') || die("Can't access this page directly");

function make_sculpty($verts,$sc,$o,$width,$height,$upsample,$smooth) {
	$image = imagecreatetruecolor($width,$height);

	$scale = new vertex(0,0,0);
	$orig = new vertex(0,0,0);

	$orig->load($o);
	$orig->mult(-1);

	$scale->load($sc);
	$scale->mult(0.5); //Radius

	$this_row = 0;
	
	foreach( $verts as $vert_row ) //Rows
	{
		$x = 0;
		$row = explode("|",$vert_row);
		$point = FALSE;
		if( count($row) == 1 ) $point = TRUE;
		$y = $height - 1 - $this_row;
		foreach( $row as $v ) //Columns
		{
			$vert = new vertex(0,0,0);
			$vert->load(explode(",",$v));
			$vert->add($orig);
			$vert->combine($scale);
	
			$vert = $vert->get_color();
			$color = $vert->allocate_color($image);

			if($point) {
				imageline($image,0,$y,$width-1,$y,$color);
				break;
			} else {
				imagesetpixel($image,$x,$y,$color);
			}
			++$x;
			if($x >= $width) break;
		}
		$this_row++;
		if( $this_row >= $height) break;
	}
	
	//Up-sample the image 
	if($upsample) 
	{
		$new_h = $height*2;
		$new_w = $width*2;
		$image_resampled = imagecreatetruecolor($new_w,$new_h);
		imagecopyresized($image_resampled , $image , 0 , 0 , 0 , 0 , $new_w , $new_h , $width, $height );
		imagedestroy($image);
		$image = $image_resampled;
	}

	if( $smooth == "gaussian" ) {
		$gaussian = array(array(1.0, 2.0, 1.0), array(2.0, 4.0, 2.0), array(1.0, 2.0, 1.0));
		imageconvolution($image, $gaussian, 16, 0);
	}
	if( $smooth == "linear" ) {
		$linear = array(array(1.0, 1.0, 1.0), array(1.0, 1.0, 1.0), array(1.0, 1.0, 1.0));
		imageconvolution($image, $linear, 9, 0);
	}

	return $image;
}

function upload_render($dir,$sculpt_id)
{
	//Convinence Variables
	$issplit = FALSE;
	if(isset($_REQUEST['split']))
	{
		$issplit = TRUE;
		$s = explode("of",stripslashes($_REQUEST['split']));
		$start = $s[0];
		$end = $s[1];
	}

	$verts = stripslashes($_REQUEST['verts']);
	$row = stripslashes($_REQUEST['row']);
	$params = stripslashes($_REQUEST['params']);

	//Parse Verticies
	$nverts = preg_replace("/> *, *</","|",$verts);
	$nverts = preg_replace("/[> <]/","",$nverts);

	//Write vertex packet splits to a split file
	//Populate the verticies on the row when all splits are received
	if($issplit) {

		$fd = fopen("$dir/$sculpt_id-$row.split","a+");
		$fd || die("Could not open file: " . "$image_id.split$row");
		fwrite($fd,$nverts);
		if($start == $end) {
			$nverts = fread($fd, filesize("$image_id.split$row"));
			fclose($fd);
			$fd = FALSE;
			unlink("$dir/$sculpt_id-$row.split");
		} else {
			$nverts = FALSE;
		}
		if($fd) fclose($fd);
	}
	
	$row_filename = "$dir/$sculpt_id.verts$row";

	//Write vertex dump to file
	if( $nverts ) {
		$fd = fopen($row_filename,"w");
		$fd || die("Could not open file: $row_filename");
		fwrite($fd,"$nverts");
		fclose($fd);
	}
}

function render($vert_dir,$render_dir,$image_id)
{
	$xverts = stripslashes($_REQUEST['w']);
	$yverts = stripslashes($_REQUEST['h']);
	$smooth = stripslashes($_REQUEST['smooth']);
	$scale = stripslashes($_REQUEST['scale']);
	$orig = stripslashes($_REQUEST['org']);
	$input = array();
	for($r = 0; $r < $yverts; ++$r)
	{
		$row_filename = "$vert_dir/$image_id.verts$r";
		if( $input[] = file_get_contents($row_filename) ) {
			unlink($row_filename);
		} else {
			die("Couldn't open file for row $r");
		}
	}
	//Parse Scale
	$scale = preg_replace("/[> <]/","",$scale);
	$scale = explode(",",$scale);

	//Parse Origin
	$orig = preg_replace("/[> <]/","",$orig);
	$orig = explode(",",$orig);

	$image = make_sculpty($input,$scale,$orig,$xverts,$yverts,TRUE,$smooth);
	
	if( imagepng($image,"$render_dir/$image_id.png") )
	{
		return fullpath("$render_dir/$image_id.png");
	}
	return false;
}?>
