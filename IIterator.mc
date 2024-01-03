import Toybox.Lang;

module MyGraph{
	typedef IIterator as interface{
		function first() as Object|Null; // returns first item (N/A => null)
		function last() as Object|Null; // returns last item (N/A => null)
		function next() as Object|Null; // returns next item (N/A => null)
		function previous() as Object|Null; // returns previous item (N/A => null)
	};
}