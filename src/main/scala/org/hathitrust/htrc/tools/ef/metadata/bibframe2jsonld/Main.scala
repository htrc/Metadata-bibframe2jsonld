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
import org.hathitrust.htrc.tools.spark.utils.Helper.stopSparkAndExit
import play.api.libs.json.Json

import scala.io.Codec
import scala.language.reflectiveCalls

object Main {
  val appName: String = "bibframe2jsonld"
  val jsonldXsl: String = new File(System.getProperty("jsonld-xsl")).getAbsolutePath

  def main(args: Array[String]): Unit = {
    val conf = new Conf(args.toIndexedSeq)
    val inputPath = conf.inputPath().toString
    val outputPath = conf.outputPath().toString
    val saveAsSeqFile = conf.saveAsSeqFile()

    // set up logging destination
    conf.sparkLog.foreach(System.setProperty("spark.logFile", _))
    System.setProperty("logLevel", conf.logLevel().toUpperCase)

    implicit val codec: Codec = Codec.UTF8

    // set up Spark context
    val sparkConf = new SparkConf()
    sparkConf.setAppName(appName)
    sparkConf.setIfMissing("spark.master", "local[*]")
    val sparkMaster = sparkConf.get("spark.master")

    val spark = SparkSession.builder()
      .config(sparkConf)
      .getOrCreate()

    val sc = spark.sparkContext

    val numPartitions = conf.numPartitions.getOrElse(sc.defaultMinPartitions)

    try {
      logger.info("Starting...")
      logger.info(s"Spark master: $sparkMaster")

      logger.info(s"Using XSL: $jsonldXsl")

      // record start time
      val t0 = System.nanoTime()

      conf.outputPath().mkdirs()

      val bibframeXmlRDD = sc.sequenceFile[String, String](inputPath, minPartitions = numPartitions)

      val errorsConvertBibframe2Jsonld = new ErrorAccumulator[(String, String), String](_._1)(sc)
      val jsonldRDD = bibframeXmlRDD.tryFlatMap { case (_, xml) =>
        Helper.bibframeXml2Jsonld(xml)
      }(errorsConvertBibframe2Jsonld)

      if (saveAsSeqFile)
        jsonldRDD
          .mapValues(_.toString())
          .saveAsSequenceFile(outputPath + "/output", Some(classOf[org.apache.hadoop.io.compress.BZip2Codec]))
      else
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
    catch {
      case e: Throwable =>
        logger.error(s"Uncaught exception", e)
        stopSparkAndExit(sc, exitCode = 500)
    }

    stopSparkAndExit(sc)
  }

}
