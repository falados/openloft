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
header('Content-type: text/plain');
define('OL_INCLUDE','1');
require_once('include/openloft_config.inc.php');
require_once('include/vertex2sculpt.inc.php');
require_once('include/vertex2cut.inc.php');

if(!isset($_REQUEST['action'])) exit;
$action = $_REQUEST['action'];
$image_id = $_REQUEST['image'];
$row = $_REQUEST['row'];

function create_dirs($image_id)
{
	global $ll_owner_key;
	if( !file_exists($ll_owner_key) ) mkdir($ll_owner_key);
	if( !file_exists("$ll_owner_key/$image_id") ) mkdir("$ll_owner_key/$image_id");
	$subdirs = array
	(
		"$ll_owner_key/$image_id/cuts",
		"$ll_owner_key/$image_id/uploads",
		"$ll_owner_key/$image_id/rendered"
	);
	foreach($subdirs as $subdir)
	{
		if(!file_exists($subdir)) mkdir($subdir);
	}
}
/*
$num = 0;
$original_id = $image_id;
while(file_exists("$ll_owner_key/rendered/$image_id"))
{
	++$num;
	$image_id = "$original_id_$num";
}
*/

if($is_ll) {
	if(isset($_REQUEST['image'])) { create_dirs($image_id); }
} else return;

$cut_dir = "$ll_owner_key/$image_id/cuts";
$upload_dir = "$ll_owner_key/$image_id/uploads";
$render_dir = "$ll_owner_key/$image_id/rendered"; 

switch($action)
{
	case "upload-cut":
		upload_cut($cut_dir);
	break;
	case "upload-render":
		upload_render($upload_dir,$image_id);
	break;
	case "render-sculpt":
		$path = render($upload_dir,$render_dir,$image_id);
		if($path)
		{
			echo("Your Sculpt Image:\n<$path>");
		} else {
			echo("Could not render sculpt");
		}
	break;
	case "render-cut":
		$path = render_cut($cut_dir,$row);
		if($path)
		{
			echo("Your Cut Image:\n<$path>");
		} else {
			echo("Could not make image for cut $row");
		}
	break;
	case "get-cut-data":
		$part = 0;
		if(isset($_REQUEST['part'])) $part = $_REQUEST['part'];
		if($data = get_cut_data($cut_dir,$row,$part) )
		{
			echo($data);
		} else {
			echo("Could not get data for cut $row");
		}
	break;
	case "get-cuts":
		echo get_cuts($cut_dir);
	break;
	case "get-sculpts":
		$files = scandir("$ll_owner_key");
		$sculpts = "";
		foreach($files as $file)
		{
			if($file == "." || $file == "..") continue;
			if(is_dir("$ll_owner_key/$file"))
			{
				$sculpts .= "$file\n";
			}
		}
		echo rtrim($sculpts);
	break;
}
?>