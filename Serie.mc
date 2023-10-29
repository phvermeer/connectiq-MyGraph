import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

module MyGraph{

	enum DrawStyle {
		DRAW_STYLE_FILLED = 0x0,
		DRAW_STYLE_LINE = 0x1,
	}
	enum MarkerType{
		MARKER_MIN = 0x1,
		MARKER_MAX = 0x2,
	}

	class Serie extends WatchUi.Drawable{
		// additional properties
		var style as DrawStyle = DRAW_STYLE_FILLED;
		var penWidth as Number = 4;
		var markers as MarkerType or Number = MARKER_MIN | MARKER_MAX;
		var xAxis as Axis?;
		var yAxis as Axis?;
		var color as ColorType;
		
		hidden var pts as IIterator;
		hidden var ptMin as DataPoint?;
		hidden var ptMax as DataPoint?;
		hidden var ptFirst as DataPoint?;
		hidden var ptLast as DataPoint?;

		hidden var index as Number = -1;

		function initialize(options as {
			:pts as IIterator, // required
			:xAxis as Axis,
			:yAxis as Axis,
			:color as ColorType, // optional
			:style as DrawStyle, //optional
			:markers as MarkerType,
			:yRangeMin as Numeric,
		}){
			Drawable.initialize(options);
			var requiredOptions = [:pts] as Array<Symbol>;
			for(var i=0; i<requiredOptions.size(); i++){
				var key = requiredOptions[i];
				if(!options.hasKey(key)){
					throw new Lang.InvalidOptionsException(Lang.format("Missing option: $1$", [key.toString()]));
				}
			}
			pts = options.get(:pts)	as IIterator;
			color = options.hasKey(:color) ? options.get(:color) as ColorType : Graphics.COLOR_PINK;
			if(options.hasKey(:style)){ style = options.get(:style) as DrawStyle; }
			if(options.hasKey(:markers)){ markers = options.get(:markers) as Number; }
		}

		function draw(dc as Dc) as Void{
			dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
			dc.fillRectangle(locX+1, locY+1, width-2, height-2);

			if(xAxis != null && yAxis != null){
				var xAxis = self.xAxis as Axis;
				var yAxis = self.yAxis as Axis;

				dc.setColor(color, Graphics.COLOR_TRANSPARENT);

				// get conversion parameters
				var xFactor = 1f*width / (xAxis.max - xAxis.min);
				var yFactor = 1f*height / (yAxis.max - yAxis.min);

				var xPrev = 0;
				var yPrev = 0;
				var xMin = locX;
				var xMax = xMin + width;
				var yMin = locY;
				var yMax = yMin + height;

				var outsideLimitsPrev = false;
				var skipPrev = true;

				if(style == DRAW_STYLE_LINE){
					dc.setPenWidth(penWidth);
					if(pts.first()){
						do{
							var pt = pts.current() as DataPoint;
							var pt_y = pt.y;
							if(pt_y != null){
								var x = locX + (pt.x - xAxis.min)*xFactor;
								var y = locY + (yAxis.max - pt_y)*yFactor;

								// check limits
								var outsideLimits = (x < xMin || x > xMax || y < yMin || y > yMax);

								// check if area within limits is crossed
								if(!skipPrev && !(outsideLimits && outsideLimitsPrev)){
									if(outsideLimits){
										var xy = interpolateXY(x, y, xPrev, yPrev, xMin, xMax, yMin, yMax);
										x = xy[0];
										y = xy[1];
									}else if(outsideLimitsPrev){
										var xy = interpolateXY(xPrev, yPrev, x, y, xMin, xMax, yMin, yMax);
										xPrev = xy[0];
										yPrev = xy[1];
									}

									// draw line
									dc.drawLine(xPrev, yPrev, x, y);
								}

								// prepare next
								xPrev = x;
								yPrev = y;
								outsideLimitsPrev = outsideLimits;
								skipPrev = false;
							}else{
								skipPrev = true;
							}
						}while(pts.next());
					}
				}else if(style == DRAW_STYLE_FILLED){
					var xys = [] as Array< Array<Numeric> >;
					if(pts.first()){
						do{
							var pt = pts.current() as DataPoint;
							var pt_y = pt.y;
							if(pt_y != null){
								var x = locX + (pt.x - xAxis.min)*xFactor;
								var y = locY + (yAxis.max - pt_y)*yFactor;

								// check limits
								var outsideLimits = (x < xMin || x > xMax || y < yMin || y > yMax);

								if(!(outsideLimits && outsideLimitsPrev)){
									if(outsideLimits){
										var xy = interpolateXY(x, y, xPrev, yPrev, xMin, xMax, yMin, yMax);
										x = xy[0];
										y = xy[1];
									}else if(outsideLimitsPrev){
										var xy = interpolateXY(xPrev, yPrev, x, y, xMin, xMax, yMin, yMax);
										xPrev = xy[0];
										yPrev = xy[1];
									}

									if(outsideLimitsPrev){
										// start polygon
										xys = [
											[xPrev, locY+height],
											[xPrev, yPrev] as Array<Numeric>
										] as Array< Array<Numeric> >;
									}
									// continu
									xys.add([x, y] as Array<Numeric>);

									if(outsideLimits){
										// close polygon
										xys.add([x, locY+height] as Array<Numeric>);
										dc.fillPolygon(xys);
									}
								}

								// prepare next
								skipPrev = false;
								xPrev = x;
								yPrev = y;
								outsideLimitsPrev = outsideLimits;
							}else{
								if(!skipPrev && !outsideLimitsPrev){
									// close previous surface
									xys.add([xPrev, locY+height] as Array<Numeric>);
									dc.fillPolygon(xys);
								}
								skipPrev = true;
							}
						}while(pts.next());

						// finish and draw last polygon
						if(!skipPrev && !outsideLimitsPrev){
							xys.add([xPrev, locY+height] as Array<Numeric>);
							dc.fillPolygon(xys);
						}
					}
				}
/*
					for(var i=0; i<pts.size(); i++){
						var pt = pts[i];
						if(pt.x >= xAxis.min && pt.x <= xAxis.max && pt.y >= yAxis.min && pt.y <= yAxis.max){
							var x = locX + (pt.x - xMin)*xFactor;
							var y = locY + (pt.y - yMin)*yFactor;

							if(xPrev == null){
								xys.add(x, yMin); // add point at x-axis
							}
							// add point
							xys.add(x, y);

							xPrev = x;
							yPrev = y;
						}else{
							if(xPrev != null){
								xys.add(x, yMin); // add point at x-axis
							}
							xPrev = null;
						}
					}
				if(xPrev != null){
					// add point at x-axis
					xys.add(x, yMin); // add point at x-axis
				}
*/
			}
		}
		hidden function interpolateY(xOld as Numeric, yOld as Numeric, xNew as Numeric, xRef as Numeric, yRef as Numeric) as Numeric{
			var rc = (yOld-yRef)/(xOld-xRef);
			var yNew = yRef + (xNew-xRef) * rc;
			return yNew;
		}
		hidden function interpolateX(xOld as Numeric, yOld as Numeric, yNew as Numeric, xRef as Numeric, yRef as Numeric) as Numeric{
			return interpolateY(yOld, xOld, yNew, yRef, xRef);
		}
		hidden function interpolateXY(
			x1 as Numeric, y1 as Numeric,
			x2 as Numeric, y2 as Numeric,
			xMin as Numeric, xMax as Numeric, yMin as Numeric, yMax as Numeric) as Array<Numeric>
		{
			if(x1 < xMin){
				y1 = interpolateY(x1, y1, xMin, x2, y2);
				x1 = xMin;
			}else if(x1 > xMax){
				y1 = interpolateY(x1, y1, xMax, x2, y2);
				x1 = xMax;
			}
			if(y1 < yMin){
				x1 = interpolateX(x1, y1, yMin, x2, y2);
				y1 = yMin;
			}else if(y1 > yMax){
				x1 = interpolateX(x1, y1, yMax, x2, y2);
				y1 = yMax;
			}
			return [x1, y1] as Array<Numeric>;
		}

		function getXmin() as Numeric|Null{
			return ptFirst != null ? ptFirst.x : null;
		}
		function getXmax() as Numeric|Null{
			return ptLast != null ? ptLast.x : null;
		}
		function getYmin() as Numeric|Null{
			return ptMin != null ? ptMin.y : null;
		}
		function getYmax() as Numeric|Null{
			return ptMax != null ? ptMax.y : null;
		}

		function updateStatistics() as Void{
			// changes can be:
			//	Null => all statistics will be cleared and renewed
			//	single DataPoint => current statistics will be updated with given DataPoint
			//	array of DataPoints => current statistics will be updated with given DataPoints

			// clear old statistics
			ptMin = null;
			ptMax = null;
			ptFirst = null;
			ptLast = null;

			if(pts.first()){
				do{
					var pt = pts.current() as DataPoint;
					var x = pt.x;
					if(x != null){
						var xMin = (ptFirst != null) ? ptFirst.x : null;
						var xMax = (ptLast != null) ? ptLast.x : null;
						if(ptMin == null || x < xMin as Numeric){
							ptFirst = pt;
						}
						if(xMax == null || x > xMax as Numeric){
							ptLast = pt;
						}
					}

					var y = pt.y;
					if(y != null){
						var yMin = (ptMin != null) ? ptMin.y : null;
						var yMax = (ptMax != null) ? ptMax.y : null;
						if(yMin == null || y < yMin as Numeric){
							ptMin = pt;
						}
						if(yMax == null || y > yMax as Numeric){
							ptMax = pt;
						}
					}
				}while(pts.next());
			}
		}

		function reset() as DataPoint|Null{
/*
			index = pts.size() > 0 ? 0 : -1;
			return (index >= 0) ? pts[index] : null;
*/
			return pts.first() ? pts.current() as DataPoint : null;
		}
		function next() as DataPoint|Null{
/*
			index = pts.size() > index+1 ? index+1 : -1;
			return (index >= 0) ? pts[index] : null;
*/
			return pts.next() ? pts.current() as DataPoint : null;
		}
		function size() as Number{
			return pts.size();
		}
	}
}