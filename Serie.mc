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
		var color2 as ColorType;
		var xCurrent as Numeric|Null; // update realtime x
		
		hidden var pts as IIterator;
		var ptMin as DataPoint?;
		var ptMax as DataPoint?;
		var ptFirst as DataPoint?;
		var ptLast as DataPoint?;

		hidden var index as Number = -1;

		function initialize(options as {
			:pts as IIterator, // required
			:xAxis as Axis,
			:yAxis as Axis,
			:color as ColorType, // optional
			:color2 as ColorType, // optional
			:style as DrawStyle, //optional
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
			color2 = options.hasKey(:color2) ? options.get(:color2) as ColorType : Graphics.COLOR_BLUE;
			if(options.hasKey(:style)){ style = options.get(:style) as DrawStyle; }
		}

		function draw(dc as Dc) as Void{
			if(xAxis != null && yAxis != null){
				var xAxis = self.xAxis as Axis;
				var yAxis = self.yAxis as Axis;

				dc.setColor(color, Graphics.COLOR_TRANSPARENT);

				// get conversion parameters
				var xFactor = xAxis.getFactor(width);
				var yFactor = yAxis.getFactor(height);

				var xPrev = 0;
				var yPrev = 0;
				var xMin = locX;
				var xMax = xMin + width;
				var yMin = locY;
				var yMax = yMin + height;
				var xColor2 = (xCurrent != null) ? locX + (xCurrent - xAxis.min) * xFactor : null;

				var outsideLimitsPrev = false;
				var skipPrev = true;

				if(style == DRAW_STYLE_LINE){
					dc.setPenWidth(penWidth);
					var pt = pts.first() as DataPoint|Null;
					while(pt != null){
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
						pt = pts.next() as DataPoint|Null;
					}
				}else if(style == DRAW_STYLE_FILLED){
					var xys = [] as Array< Array<Numeric> >;
					var pt = pts.first() as DataPoint|Null;
					while(pt != null){
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
									// start new polygon
									xys = [
										[xPrev, locY+height],
										[xPrev, yPrev] as Array<Numeric>
									] as Array< Array<Numeric> >;
								}else if(skipPrev){
									// start new polygon
									xys.add([x, locY+height] as Array<Numeric>);										
								}

								// change color at xSplit
								if(xColor2 != null && xPrev < xColor2 && x >= xColor2){
									// add additional point for xCurrent
									var yColor2 = MyMath.interpolateY(xPrev, yPrev, x, y, xColor2);
									xys.add([xColor2, yColor2] as Array<Numeric>);
									xys.add([xColor2, locY + height] as Array<Numeric>);
									dc.fillPolygon(xys);

									// from here start with color2
									dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
									xys = [[xColor2, locY + height], [xColor2, yColor2]] as Array< Array<Numeric> >;
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
						pt = pts.next();
					}

					// finish and draw last polygon
					if(!skipPrev && !outsideLimitsPrev){
						xys.add([xPrev, locY+height] as Array<Numeric>);
						dc.fillPolygon(xys);
					}
				}
			}
		}
		hidden function interpolateY(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, x as Numeric) as Numeric{
			var rc = (y1-y2)/(x1-x2);
			var y = y1 + (x-x1) * rc;
			return y;
		}
		hidden function interpolateX(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, y as Numeric) as Numeric{
			return interpolateY(y1, x1, y2, x2, y);
		}
		hidden function interpolateXY(x1 as Numeric, y1 as Numeric, x2 as Numeric, y2 as Numeric, xMin as Numeric, xMax as Numeric, yMin as Numeric, yMax as Numeric) as Array<Numeric>{
			if(x1 < xMin){
				y1 = interpolateY(x1, y1, x2, y2, xMin);
				x1 = xMin;
			}else if(x1 > xMax){
				y1 = interpolateY(x1, y1, x2, y2, xMax);
				x1 = xMax;
			}
			if(y1 < yMin){
				x1 = interpolateX(x1, y1, x2, y2, yMin);
				y1 = yMin;
			}else if(y1 > yMax){
				x1 = interpolateX(x1, y1, x2, y2, yMax);
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

			var pt = pts.first() as DataPoint|Null;
			while(pt != null){
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

				pt = pts.next() as DataPoint;
			}
		}
	}
}