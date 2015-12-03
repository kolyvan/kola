##Kola

Kolyvan's laconic configuration file format (kola) with a pretty simple notation.

####Example

	title "the example of .kola file"
	last-modified (date)2015-12-02T19:10:00GMT
	red (color)0xff0000
	blue (color)0x00ff00

	section {

		# numbers
		id 123456, ratio -10.05, zero 0

		# boolean
    	flag true, untrue false

    	# strings
    	string "laconic and very simple format"
    	escaped "\tescaped text:\n'\u041A\u041E\u041B\u0410'"
    	multi-line "Lorem ipsum dolor sit amet, consectetur adipisicing elit,
		sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

		# array
    	bag-of-things [ red blue 3.14 false
        	            [ 1, 2, 3 ]
            	        { foo 'bar' } ]

		# dictionary
    	table # =
    	{
    		# commas and assigments are optional
    		a 1, b 2, c 3 d=4 
		} 

		view-frame (rect){x 10.0, y 20.0, w 64.0, h 16.0}
		square-size (size)[20 10]
	}

###Rules

* A content of .kola file is a sequence of key-value pairs.
* Key is an alphanumeric sequence.
* Value is a number, boolean, string, array, dictionary and reference.
* Value may has a typename as prefix in brackets ala '(color)value'
* String are surrounded by quotation marks, may include escaped sequences, and may be multi-lined.
* Array is a sequence of values surrounded by [ ].
* Dictonary is a sequence of key-value pairs surrounded by { }.
* Comma (,) between pairs in dictionary and between values in array is optional (only for readability).
* Assignment (=) in a pair is optional too (only for readability).
* Comments begins from '#' till end of line.
* Reference is a key's name, an unknown reference will be interpreted as string.
* '_' is a placeholder for unspecified value (nsnull in objective-c).

###Implementation

Objective-C framework with Reader class.

	NSDictionary *dict; NSError *error;
	dict = [KolaFormatReader dictionaryWithString:string error:&error];

For more info see Demo project. 




