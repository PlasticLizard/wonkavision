package org.wonkavision.core

object Rate {

	def apply(n: Int, d: Int) = new Rate(n, d)

  def parse(rateString : String) = {
    if (rateString == "0" || rateString == "-") {
      ZERO
    } else {
      val parts = rateString.split("/").map(_.toInt)
      new Rate(parts(0), parts(1))
    }
  }
	
  val ZERO = new Zero()

	implicit def rateToDouble(rate : Rate) : Double  = {
		rate.toDouble
	}

 	implicit object RateIsNumeric extends RateIsNumeric with RateOrdering

}


class Rate(val numer: Int, val denom: Int) extends Serializable{

    def + (that: Rate): Rate = new Rate(numer + that.numer, denom + that.denom)

    def - (that: Rate): Rate = new Rate(numer - that.numer, denom - that.denom)

    def toDouble = if (denom == 0) 0.0 else numer.toDouble / denom.toDouble

    override def toString = if (isEmpty) "-" else numer +"/"+ denom

    def isEmpty = denom == 0


 }

 case class Zero() extends Rate(0,0)

 trait RateIsNumeric extends Numeric[Rate] {
 	def plus(x: Rate, y: Rate): Rate = x + y
  	def minus(x: Rate, y: Rate): Rate = x - y
  	def times(x: Rate, y: Rate): Rate = throw new UnsupportedOperationException()
  	def quot(x: Rate, y: Rate): Rate = throw new UnsupportedOperationException()
  	def rem(x: Rate, y: Rate): Rate =  throw new UnsupportedOperationException()
  	def negate(x: Rate): Rate = throw new UnsupportedOperationException()
  	def fromInt(x: Int): Rate = new Rate(x,1)
  	def toInt(x: Rate): Int = x.toDouble.toInt
  	def toLong(x: Rate): Long = x.toDouble.toLong
  	def toFloat(x: Rate): Float = x.toDouble.toFloat
  	def toDouble(x: Rate): Double = x.toDouble
 }

 trait RateOrdering extends Ordering[Rate] {
 	def compare(x : Rate, y: Rate) = x.toDouble.compare(y.toDouble)
 }