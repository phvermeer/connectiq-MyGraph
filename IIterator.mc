import Toybox.Lang;

module MyGraph{
	typedef IIterator as interface{
		function current() as Object or Null; // get current item
		function size() as Number;
		function first() as Boolean; // select first item as current (N/A => false)
		function last() as Boolean; // select last item as current (N/A => false)
		function next() as Boolean; // select next item as current (N/A => false)
		function previous() as Boolean; // select previous item as current (N/A => false)
	};
}