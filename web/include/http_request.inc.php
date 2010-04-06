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

/*
* Access the HTTP Request
*/
class http_request {

	/** additional HTTP headers not prefixed with HTTP_ in $_SERVER superglobal */
	var $add_headers = array('CONTENT_TYPE', 'CONTENT_LENGTH');

	/**
	* Construtor
	* Retrieve HTTP Body
	* @param Array Additional Headers to retrieve
	*/
	function http_request($add_headers = false) {
	
		$this->retrieve_headers($add_headers);
		$this->body = @file_get_contents('php://input');
	}
	
	/**
	* Retrieve the HTTP request headers from the $_SERVER superglobal
	* @param Array Additional Headers to retrieve
	*/
	function retrieve_headers($add_headers = false) {
		
		if ($add_headers) {
			$this->add_headers = array_merge($this->add_headers, $add_headers);
		}
	
		if (isset($_SERVER['HTTP_METHOD'])) {
			$this->method = $_SERVER['HTTP_METHOD'];
			unset($_SERVER['HTTP_METHOD']);
		} else {
			$this->method = isset($_SERVER['REQUEST_METHOD']) ? $_SERVER['REQUEST_METHOD'] : false;
		}
		$this->protocol = isset($_SERVER['SERVER_PROTOCOL']) ? $_SERVER['SERVER_PROTOCOL'] : false;
		$this->request_method = isset($_SERVER['REQUEST_METHOD']) ? $_SERVER['REQUEST_METHOD'] : false;
		
		$this->headers = array();
		foreach($_SERVER as $i=>$val) {
			if (strpos($i, 'HTTP_') === 0 || in_array($i, $this->add_headers)) {
				$name = str_replace(array('HTTP_', '_'), array('', '-'), $i);
				$this->headers[$name] = $val;
			}
		}
	}
	
	/** 
	* Retrieve HTTP Method
	*/
	function method() {
		return $this->method;
	}
	
	/** 
	* Retrieve HTTP Body
	*/
	function body() {
		return $this->body;
	}
	
	/** 
	* Retrieve an HTTP Header
	* @param string Case-Insensitive HTTP Header Name (eg: "User-Agent")
	*/
	function header($name) {
		$name = strtoupper($name);
		return isset($this->headers[$name]) ? $this->headers[$name] : false;
	}
	
	/**
	* Retrieve all HTTP Headers 
	* @return array HTTP Headers
	*/
	function headers() {
		return $this->headers;
	}
	
	/**
	* Return Raw HTTP Request (note: This is incomplete)
	* @param bool ReBuild the Raw HTTP Request
	*/
	function raw($refresh = false) {
	
		if (isset($this->raw) && !$refresh) {
			return $this->raw; // return cached
		}
	
		$headers = $this->headers();
		$this->raw = "{$this->method}\r\n";
		
		foreach($headers as $i=>$header) {
			$this->raw .= "$i: $header\r\n";
		}
		
		$this->raw .= "\r\n{$http_request->body}";
		
		return $this->raw;
	}

}?>
