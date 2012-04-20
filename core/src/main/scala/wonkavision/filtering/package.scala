package org.wonkavision.core

import org.joda.time.DateTime

package object filtering {
	implicit def dateTimeOrdering: Ordering[DateTime] = Ordering.fromLessThan(_ isBefore _)
}