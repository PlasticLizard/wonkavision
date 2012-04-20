package org.wonkavision.core.measures

import org.wonkavision.core.Measure
import org.wonkavision.core.MeasureFormat
import org.wonkavision.core.MeasureFormat._

class Calculation(
	name : String,
	format : MeasureFormat = MeasureFormat.Decimal,
  val calcFunction:  () => Double
) extends Measure(name, format) {
}