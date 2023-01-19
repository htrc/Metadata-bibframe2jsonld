package org.hathitrust.htrc.tools.ef.metadata.bibframe2jsonld

import java.io.File
import java.nio.charset.StandardCharsets

import com.gilt.gfc.time.Timer
import com.sun.org.apache.bcel.internal.generic._
import org.apache.commons.io.FileUtils
import org.apache.hadoop.fs.Path
import org.apache.spark.sql.SparkSession
import org.apache.spark.{SparkConf, SparkContext}
import org.hathitrust.htrc.tools.ef.metadata.bibframe2jsonld.Helper.logger
import org.hathitrust.htrc.tools.spark.errorhandling.ErrorAccumulator
import org.hathitrust.htrc.tools.spark.errorhandling.RddExtensions._
import play.api.libs.json.Json

import scala.io.Codec
import scala.language.reflectiveCalls

object Main {
  val appName: String = "marcjson2bibframexml"
  val jsonldXsl: String = new File(System.getProperty("jsonld-xsl")).getAbsolutePath

  def main(args: Array[String]): Unit = {
    val conf = new Conf(args.toIndexedSeq)
    val inputPath = conf.inputPath().toString
    val outputPath = conf.outputPath().toString

    conf.outputPath().mkdirs()

    // set up logging destination
    conf.sparkLog.toOption match {
      case Some(logFile) => System.setProperty("spark.logFile", logFile)
      case None =>
    }
    System.setProperty("logLevel", conf.logLevel().toUpperCase)

    // set up Spark context
    val sparkConf = new SparkConf()
    sparkConf.setAppName(appName)
    sparkConf.setIfMissing("spark.master", "local[*]")

    val spark = SparkSession.builder()
      .config(sparkConf)
      .getOrCreate()

    implicit val sc: SparkContext = spark.sparkContext
    implicit val codec: Codec = Codec.UTF8

    val numPartitions = conf.numPartitions.getOrElse(sc.defaultMinPartitions)

    logger.info("Starting...")

    // record start time
    val t0 = System.nanoTime()

    logger.info(s"Using XSL: $jsonldXsl")

    val bibframeXmlRDD = sc.sequenceFile[String, String](inputPath, minPartitions = numPartitions)

    val errorsConvertBibframe2Jsonld = new ErrorAccumulator[(String, String), String](_._1)(sc)
    val jsonldRDD = bibframeXmlRDD.tryMapValues(Helper.bibframeXml2Jsonld)(errorsConvertBibframe2Jsonld)

//    jsonldRDD
//      .mapValues(_.toString())
//      .saveAsSequenceFile(outputPath + "/output", Some(classOf[org.apache.hadoop.io.compress.BZip2Codec]))

    jsonldRDD.foreach { case (id, json) =>
      val cleanId = id.replace(":", "+").replace("/", "=")
      FileUtils.writeStringToFile(new File(outputPath, s"$cleanId.json"), Json.prettyPrint(json), StandardCharsets.UTF_8)
    }

    if (errorsConvertBibframe2Jsonld.nonEmpty)
      logger.info("Writing error report(s)...")

    if (errorsConvertBibframe2Jsonld.nonEmpty)
      errorsConvertBibframe2Jsonld.saveErrors(new Path(outputPath, "bibframe2jsonld_errors.txt"), _.toString)

    // record elapsed time and report it
    val t1 = System.nanoTime()
    val elapsed = t1 - t0

    logger.info(f"All done in ${Timer.pretty(elapsed)}")
  }

}
