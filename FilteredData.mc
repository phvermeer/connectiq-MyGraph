import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Timer;
import MyMath;
import MyList;

module MyGraph{
	class FilteredData extends MyList.FilteredList{
		// working variables
		var maxCount as Number;
		var reducedCount as Number;
		var bufferStepCount as Number = 40;

		// point indicators for min and max values
		var ptMin as DataPoint|Null = null; // point containing the lowest value
		var ptMax as DataPoint|Null = null; // point containing the highest value

		// current min and max values
		var xMin as Numeric|Null = null;
		var xMax as Numeric|Null = null;
		var yMin as Numeric|Null = null;
		var yMax as Numeric|Null = null;

	
		// timer to add data in smaller parts to prevent "Error: Watchdog Tripped Error - Code Executed Too Long"
		hidden var bufferTimer as Timer.Timer = new Timer.Timer();
		hidden var buffer as Array<DataPoint> = [] as Array<DataPoint>; // buffer of array with [x,y] values
		hidden var bufferBusy as Boolean = false; // indicates if the bufferTimer is running
		public var onUpdated as Null|Method;
		public function isBusy() as Boolean{ return bufferBusy; }

		function initialize(options as {
			:maxCount as Number, 
			:reducedCount as Number,
			:onUpdated as Method() as Void,
		}){
			maxCount = options.hasKey(:maxCount) ? options.get(:maxCount)as Number: 60;
			reducedCount = options.hasKey(:reducedCount) ? options.get(:reducedCount) as Number : (maxCount * 3 / 4).toNumber();
			onUpdated = options.get(:onUpdated) as Null|Method() as Void;

			//MyFilteredList.initialize(method(:rankDataPoint) as Method(previous as Object, item as Object, next as Object) as Numeric?);
			FilteredList.initialize(method(:rankDataPoint) as Method(ptBefore as Object, pt as Object , ptAfter as Object) as Numeric|Null);
		}

		function rankDataPoint(objBefore as Object, obj as Object , objAfter as Object) as Numeric|Null{
			var ptBefore = objBefore as DataPoint;
			var pt = obj as DataPoint;
			var ptAfter = objAfter as DataPoint;

			// Use VisvalingamFilter
			// Have all points a valid numeric value
			var yBefore = ptBefore.y;
			var y = pt.y;
			var yAfter = ptAfter.y;
			if(yBefore != null && y != null && yAfter != null){
				// now we can calculate the ranking
				return getTriangleSurface(ptBefore.x, yBefore, pt.x, y, ptAfter.x, yAfter);
			}else if(yBefore == null && y == null && yAfter == null){
				// if the y value is null and surrounded by other null values, this value can be deleted
				return 0;
			}else{
				// No ranking => do NOT delete this value when filtered
				return null;
			}
		}

		hidden function getTriangleSurface(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, x3 as Numeric, y3 as Numeric) as Numeric{
			return MyMath.abs(0.5 * (x1 * y2 + x2 * y3 + x3 * y1 - x1 * y3 - x2 * y1 - x3 * y2));
		}

		public function add(obj as Object) as Void{
			if(obj instanceof DataPoint){
				addDataPoint(obj as DataPoint);
			}
		}
		public function addDataPoint(pt as DataPoint) as Void{
			addToBuffer(pt);
		}
		
		public function firstDataPoint() as DataPoint|Null{
			return first() as DataPoint|Null;				
		}
		public function lastDataPoint() as DataPoint|Null{
			return last() as DataPoint|Null;				
		}
		public function nextDataPoint() as DataPoint|Null{
			return next() as DataPoint|Null;
		}
		hidden function addToBuffer(pt as DataPoint) as Void{
			buffer.add(pt);
			// start timer to process the buffered items 
			if(!bufferBusy){
				// start processing the buffer timer
				bufferTimer.start(method(:bufferProcess), 100, true);
				bufferBusy = true;
			}
		}
		public function bufferProcess() as Void{
			// process some items of the buffer
			var count = MyMath.min([self.buffer.size(), bufferStepCount] as Array<Number>) as Number;
			var ptsNew = buffer.slice(null, count);
			buffer = buffer.slice(count, null);

			// Add data points
			for(var i=0; i<ptsNew.size(); i++){
				var pt = ptsNew[i]; 
				addDataPointDelayed(pt);
			}	

			// Check if the data should be filtered
			if(size() > maxCount){
				filterSize(reducedCount);
			}

			// stop timer if buffer is empty	
			if(buffer.size() == 0){
				bufferTimer.stop();
				bufferBusy = false;
				// System.println("Finished processing");
				if(onUpdated != null){
					onUpdated.invoke();
				}
			}
		}

		public function clear() as Void{
			// stop processing the buffer
			bufferTimer.stop();

			// clear all data
			xMin = null;
			xMax = null;
			yMin = null;
			yMax = null;
			ptMin = null;
			ptMax = null;

			buffer = [] as Array<DataPoint>;
			FilteredList.clear();
		}

		hidden function addDataPointDelayed(pt as DataPoint) as Void{
			var x = pt.x;
			var y = pt.y;
			//System.println(Lang.format("(x,y) = ( $1$, $2$ )", [x, y]));
			if(y != null){
				if(yMin != null && yMax != null){
					if(y < yMin){
						yMin = y;
						ptMin = pt;
					}else if(y > yMax as Numeric){
						yMax = y;
						ptMax = pt;
					}
				}else{
					// init min/max values
					yMin = y;
					yMax = y;
					ptMin = pt;
					ptMax = pt;
				}
			}
			if(xMin != null && xMax != null){
				// update min/max values
				if(x < xMin){
					xMin = x;
				}else if(x > xMax as Numeric){
					xMax = x;
				}
			}else{
				xMin = x;
				xMax = x;
			}

			// add new point
			var item = createItem(pt);
			insertItem(item, _last);
			if(y == null){
				// remove previous null value if that values is inbetween two null values

				// previous listItem
				var itemPrev = item.previous;
				if(itemPrev != null){
					// DataPoint stored in that listItem
					var ptPrev = itemPrev.object as DataPoint;
					if(ptPrev.y == null){
						// listItem before previous listItem
						var itemPrevPrev = itemPrev.previous;
						if(itemPrevPrev != null){
							// DataPoint stored in that listItem
							var ptPrevPrev = itemPrevPrev.object as DataPoint;
							if(ptPrevPrev.y == null){
								// remove listitem with useless datapoint
								deleteItem(itemPrev);
							}
						}
					}
				}
			}
		}
	}
}