import Toybox.Lang;
import Toybox.Time;

module MyGraph{
	class DataPoint{
		var x as Numeric;
		var y as Numeric|Null;
		function initialize(x as Moment|Numeric, y as Numeric|Null){
			self.x = (x instanceof Moment) ? x.value() : x;
			self.y = y;
		}

		function getRankValue(predecessor as Object, succesor as Object) as Numeric|Null{
			// return values [0 .. ∞] or null
			// 	0 => lowest Priority
			//	null => highest Priority (can not be missed)

			var ptPre = predecessor as DataPoint;
			var ptPost = succesor as DataPoint;

			var xPre = ptPre.x;
			var yPre = ptPre.y;
			var xPost = ptPost.x;
			var yPost = ptPost.y;

			if(yPre == null && y == null && yPost == null){
				return 0;
			}else if(yPre != null && y != null && yPost != null){
				var x1 = x - xPre;
				var x2 = xPost - xPre;
				var y1 = y - yPre;
				var y2 = yPost - yPre;

				//return MyMath.abs(0.5 * (xPre * y + x * yPost + xPost * yPre - xPre * yPost - x * yPre - xPost * y));
				return MyMath.abs(0.5 * (x1 * y2 - x2 * y1));
			}else{
				return null;
			}
		}
	}
}