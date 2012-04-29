package org.wonkavision.core.measures

import org.wonkavision.core.Measure
import org.wonkavision.core.MeasureFormat
import org.wonkavision.core.MeasureFormat._

class Sum(name : String, format : MeasureFormat = MeasureFormat.Decimal)
	extends Measure(name, format)