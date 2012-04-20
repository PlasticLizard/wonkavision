package org.wonkavision.core.filtering

object FilterOperator extends Enumeration {
	type FilterOperator = Value
	val Gt, Gte, Lt, Lte, Eq, Ne, In, Nin = Value
}