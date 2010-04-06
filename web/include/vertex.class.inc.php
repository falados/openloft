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
defined('OL_INCLUDE') || die("Can't access this page directly");

class vertex {
	var $x=0.0;
	var $y=0.0;
	var $z=0.0;
	//Initialize Constructor
	function vertex($x,$y,$z)
	{
		$this->x = $x;
		$this->y = $y;
		$this->z = $z;
	}
	//loads from a SL vertex: <x,y,z>
	function parse_llvector($ll_vector)
	{
		$matches = array();
		if( preg_match ('/<\s*(-?\d+(.\d*)?)\s*,\s*(-?\d+(.\d*)?)\s*,\s*(-?\d+(.\d*)?)\s*>/',trim($ll_vector), $matches) )
		{
			$this->x = floatval($matches[1]);
			$this->y = floatval($matches[3]);
			$this->z = floatval($matches[5]);
		}
	}
	//Loads x y z from a length 3 array
	function load(/*.array.*/ $arr) {
		$this->x = floatval($arr[0]);
		$this->y = floatval($arr[1]);
		$this->z = floatval($arr[2]);
	}
	//Multiplies by another vertex
	function mult($scalar=1.0)
	{
		$this->x *=floatval($scalar);
		$this->y *=floatval($scalar);
		$this->z *=floatval($scalar);
	}

	//Gets a new vertex by combining this vertex and the parameter
	//It interpolates using linear interpolation
	//if t = 0, then the return value is $this
	//if t = 1, then the return value is $vertex
	//if t is between 0 and 1 then the return value will be between $this and $vertex
	function get_interp($vertex, $t)
	{
		return new vertex(
			$this->x * (1.0-$t) + $vertex->x*$t,
			$this->y * (1.0-$t) + $vertex->y*$t,
			$this->z * (1.0-$t) + $vertex->z*$t
		);
	}
	
	//Gets a new vertex that represents color
	//This only works if this vertex has x,y,z values that range between -1 and 1
	function get_color()
	{
		$vert = new vertex(
			floor(127*round($this->x,FLOAT_PRECISION))+128,
			floor(127*round($this->y,FLOAT_PRECISION))+128,
			floor(127*round($this->z,FLOAT_PRECISION))+128
		);
		if($vert->x > 255) $vert->x = 255;
		if($vert->y > 255) $vert->y = 255;
		if($vert->z > 255) $vert->z = 255;
		
		if($vert->x < 0) $vert->x = 0;
		if($vert->y < 0) $vert->y = 0;
		if($vert->z < 0) $vert->z = 0;
		
		return $vert;
	}
	
	//Allocates a color for the given image using the x,y,z values as the inputs to r,g,b
	function allocate_color(&$image)
	{
		return imagecolorallocate($image,intval($this->x),intval($this->y),intval($this->z));
	}
	
	//Divides each element by the corresponding element in the other vertex
	function combine(/*.vertex.*/ $vertex)
	{
		$this->x /= $vertex->x;
		$this->y /= $vertex->y;
		$this->z /= $vertex->z;
	}
	//Adds each element of the given vertex to its corresponding element
	function add(/*.vertex.*/ $vertex)
	{
		$this->x += $vertex->x;
		$this->y += $vertex->y;
		$this->z += $vertex->z;
	}
	function get_array() {
		return array($this->x,$this->y,$this->z);
	}
	function toString() {
		return "<{$this->x},{$this->y},{$this->z}>";
	}
};?>
