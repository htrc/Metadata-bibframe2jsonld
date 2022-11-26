package org.hathitrust.htrc.tools.ef.metadata.bibframe2jsonld

import java.io.{ByteArrayInputStream, StringReader, StringWriter}
import java.nio.file.{Files, Paths}

import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.{StreamResult, StreamSource}
import net.sf.saxon.Configuration
import net.sf.saxon.lib.FeatureKeys
import org.hathitrust.htrc.tools.ef.metadata.bibframe2jsonld.Main.jsonldXsl
import org.slf4j.{Logger, LoggerFactory}
import play.api.libs.json.{JsValue, Json}

object Helper {
  @transient lazy val logger: Logger = LoggerFactory.getLogger(Main.appName)

  val systemId: String = Paths.get(jsonldXsl).toUri.toString
  val xslBytes: Array[Byte] = Files.readAllBytes(Paths.get(jsonldXsl))

  def bibframeXml2Jsonld(xmlString: String): JsValue = {
    val xmlSource = new StreamSource(new StringReader(xmlString))
    val xslSource = new StreamSource(new ByteArrayInputStream(xslBytes))
    xslSource.setSystemId(systemId)

    val xmlStringWriter = new StringWriter()
    val result = new StreamResult(xmlStringWriter)
    val transformerFactory = TransformerFactory.newInstance()
    if (transformerFactory.isInstanceOf[net.sf.saxon.TransformerFactoryImpl])
      transformerFactory.setAttribute(FeatureKeys.RECOVERY_POLICY, Integer.valueOf(Configuration.RECOVER_SILENTLY))
    val transformer = transformerFactory.newTransformer(xslSource)
    transformer.transform(xmlSource, result)

    val jsonString = xmlStringWriter.toString

    Json.parse(jsonString)
  }
}