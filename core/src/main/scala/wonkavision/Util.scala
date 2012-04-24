package org.wonkavision.core

import scala.annotation.tailrec

object Util {
	def combine[T](elements : Seq[T]) = {
		val combos = for (i <- elements.indices) yield elements.combinations(i+1)
		combos.flatten
	}
	// Thanks to http://stackoverflow.com/questions/10290189/how-to-make-this-recursive-method-tail-recursive-in-scala
	def product[T](listOfLists: List[List[T]]): List[List[T]] = {
  		@tailrec def innerProduct[T](listOfLists: List[List[T]], accum: List[List[T]]): List[List[T]] =
		    listOfLists match {
		      case Nil => accum
		      case xs :: xss => innerProduct(xss, for (y <- xs; a <- accum) yield y :: a)
		    }
	  	innerProduct(listOfLists.reverse, List(Nil))
	}
}