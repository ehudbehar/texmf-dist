// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.util

import java.io.IOException
import java.nio.file.Path
import org.apache.velocity.VelocityContext
import org.apache.velocity.exception.MethodInvocationException
import org.apache.velocity.exception.ParseErrorException
import org.apache.velocity.exception.ResourceNotFoundException
import org.apache.velocity.exception.TemplateInitException
import org.apache.velocity.runtime.RuntimeConstants
import org.apache.velocity.runtime.RuntimeSingleton
import org.apache.velocity.runtime.parser.ParseException
import org.islandoftex.texplate.exceptions.TemplateMergingException
import org.islandoftex.texplate.model.Template
import org.islandoftex.texplate.util.HandlerUtils.handlers
import org.slf4j.helpers.NOPLoggerFactory

/**
 * Merging utilities.
 *
 * @version 1.0
 * @since 1.0
 */
object MergingUtils {
    /**
     * Merges both template and data.
     *
     * @param template The template object.
     * @param map The data map.
     * @param output The output path.
     * @param cmap The configuration map.
     * @return The length of the generated output.
     * @throws TemplateMergingException The merging failed.
     */
    @JvmStatic
    @Throws(TemplateMergingException::class)
    @Suppress("TooGenericExceptionCaught")
    fun mergeTemplate(
        template: Template,
        map: Map<String, String?>,
        output: Path,
        cmap: Map<String, Any>
    ): Long {
        // create the context map
        val context = handle(template, map, cmap)
        // create a file writer for the output reference
        try {
            output.toFile().writer().use { writer ->
                // the document is actually read into a string reader
                val reader = template.document!!.reader()
                // load both runtime services and the template model from Velocity
                val services = RuntimeSingleton.getRuntimeServices()
                services.addProperty(RuntimeConstants.RUNTIME_LOG_INSTANCE,
                        NOPLoggerFactory().getLogger(""))
                val reference = org.apache.velocity.Template()
                // set both runtime services and document data into the template document
                reference.setRuntimeServices(services)
                reference.data = services.parse(reader, reference)
                reference.initDocument()
                // create the context based on the data map previously set
                val entries = VelocityContext(context)
                // merge both template and data into the file writer
                reference.merge(entries, writer)
            }
        } catch (exception: Exception) {
            // TODO: simplify
            when (exception) {
                is IOException, is MethodInvocationException, is ParseErrorException,
                is ParseException, is ResourceNotFoundException, is TemplateInitException ->
                    throw TemplateMergingException("An error occurred while " +
                            "trying to merge the template reference with the " +
                            "provided data. Make sure the template is correct " +
                            "and try again. The raised exception might give us " +
                            "some hints on what exactly happened. Typically, " +
                            "make sure the template strictly follows the " +
                            "Velocity 2.0 language syntax.", exception)
                else -> throw TemplateMergingException("Fatal error occured. " +
                        "This error should never happen. Please make a detailed " +
                        "report to the developers.")
            }
        }
        // simply return the length of the generated output file
        return output.toFile().length()
    }

    /**
     * Handles the context map.
     *
     * @param template The template model.
     * @param map The context map.
     * @param configmap The map from a configuration file.
     * @return The new context map.
     */
    private fun handle(
        template: Template,
        map: Map<String, String?>,
        configmap: Map<String, Any>
    ): Map<String, Any?> {
        // no handlers found
        return if (template.handlers.isEmpty()) {
            // create a new map from the command line map and put the values from
            // the configuration file cmap, if absent
            configmap.mapValues { it.value.toString() }.plus(map)
        } else {
            // get default handlers and set the resulting map
            val result: MutableMap<String, Any?> = mutableMapOf()
            // check each key from the map
            map.forEach { (key: String, value: String?) ->
                // there is a handler for the current key
                if (template.handlers.containsKey(key) &&
                        handlers.containsKey(template.handlers[key])) {
                    // apply the handler and store the value in the map
                    result[key] = handlers[template.handlers[key]]!!.apply(value)
                } else {
                    // simply store the value
                    result[key] = value
                    // TODO: should we warn about an invalid handler?
                }
            }

            // put remaining values from the configuration file, if absent
            configmap.plus(result)
        }
    }
}
