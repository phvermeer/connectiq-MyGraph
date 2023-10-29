import Toybox.Lang;

module MyGraph{
    class Axis{
        var min as Numeric;
        var max as Numeric;

        function initialize(min as Numeric, max as Numeric){
            self.min = min;
            self.max = max;
        }
    }
}