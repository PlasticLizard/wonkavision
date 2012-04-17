package org.wonkavision.core

import MeasureFormat._

abstract class Measure(
	val name : String,
	val format : MeasureFormat = MeasureFormat.Decimal
)