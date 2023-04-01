// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate

import java.nio.file.Path
import java.util.concurrent.Callable
import kotlin.math.ln
import kotlin.math.pow
import org.islandoftex.texplate.exceptions.InvalidTemplateException
import org.islandoftex.texplate.model.Configuration
import org.islandoftex.texplate.model.Template
import org.islandoftex.texplate.util.MergingUtils.mergeTemplate
import org.islandoftex.texplate.util.MessageUtils.error
import org.islandoftex.texplate.util.MessageUtils.line
import org.islandoftex.texplate.util.MessageUtils.status
import org.islandoftex.texplate.util.PathUtils.getTemplatePath
import org.islandoftex.texplate.util.ValidatorUtils.validate
import picocli.CommandLine

/**
 * The template processing class.
 *
 * @version 1.0
 * @since 1.0
 */
@CommandLine.Command(usageHelpWidth = 70, name = "texplate")
class TemplateProcessing : Callable<Int> {
    // the file output, which will hold the result of the merging of both template
    // and context data map from command line
    @CommandLine.Option(
            names = ["-o", "--output"],
            description = ["The output file in which the chosen " +
                    "template will be effectively written. Make sure " +
                    "the directory has the correct permissions for " +
                    "writing the output file."],
            required = true,
            type = [Path::class]
    )
    private val output: Path? = null

    // the template name
    @CommandLine.Option(
            names = ["-t", "--template"],
            description = ["The name of the template. The tool will " +
                    "search both user and system locations and set the " +
                    "template model accordingly, based on your specs."]
    )
    private var template: String? = null

    // the context data map that holds a set of key/value pairs to be merged
    // with the template
    @CommandLine.Option(
            names = ["-m", "--map"],
            description = ["The contextual map that provides the " +
                    "data to be merged in the template. This parameter " +
                    "can be used multiple times. You can specify a map " +
                    "entry with the key=value syntax (mind the entry " +
                    "separator)."],
            arity = "1..*"
    )
    private var map: Map<String, String>? = null

    @CommandLine.Option(
            names = ["-c", "--config"],
            description = ["The configuration file in which the tool " +
                    "can read template data, for automation purposes. Make " +
                    "sure to follow the correct specification when writing " +
                    "a configuration file."],
            type = [Path::class]
    )
    private val configuration: Path? = null

    /**
     * The application logic, enclosed as a call method.
     *
     * @return An integer value denoting the exit status.
     * @throws Exception An exception was raised in the application logic.
     */
    @Throws(Exception::class)
    override fun call(): Int {
        // the exit status, originally set as a valid value
        var exit = 0
        // configuration halt flag, indicating whether the tool has to end earlier
        var halt = false
        var cmap: Map<String, Any> = mutableMapOf()
        // ensure the context data map is at least instantiated
        ensureMap()
        // there is a configuration file found in the command line
        if (has(configuration)) {
            line("Checking configuration")
            try {
                val config = Configuration.fromPath(configuration!!)
                // the configuration file seems to be valid, proceed
                status(true)
                // check if the configuration has a proper template
                if (has(config.template)) {
                    // if so, build the template if, and only if, there's no one already
                    // set through command line
                    template = ensure(template, config.template)
                }
                // check if the configuration has a proper string/string map
                if (has(config.map)) {
                    // set the main configuration map to be dealt later on
                    cmap = config.map
                }
                line("Adjusting variables from file")
                status(true)
                println()
            } catch (e: InvalidTemplateException) {
                // an error occurred, print it, set exit code and halt
                status(false)
                error(e)
                exit = -1
                halt = true
            }
        } else {
            line("Configuration file mode disabled")
            status(true)
            line("Entering full command line mode")
            // there's no configuration file, so we need to check whether there is
            // not a pattern set in the command line
            if (!has(template)) {
                status(false)
                error(Exception("The template was not set " +
                        "in the command line through the -t/--template " +
                        "option. If not explicitly specified in a " +
                        "configuration file, this option becomes mandatory, " +
                        "so make sure to define it  either in the command " +
                        "line or in a proper configuration file."))
                exit = -1
                halt = true
            } else {
                status(true)
                println()
            }
        }
        // check whether we should halt prematurely
        if (!halt) {
            println("Please, wait...")
            println()
            // now we need to obtain the actual template from a file stored either
            // in the user home or in the system
            line("Obtaining reference")
            try {
                // let us try to get the corresponding file from the template pattern
                val file = getTemplatePath(template!!)
                // the actual template file was found, so we can proceed to
                // the next phase
                status(true)
                line("Composing template")
                // attempts to retrieve the template attributes from the referenced file
                // to the actual template object
                val template = Template.fromPath(file)
                // the template composition was successful, so we can move on to the
                // next phase
                status(true)
                // once the template object is populated, we need to verify if both
                // template and data map are not somehow conflicting
                line("Validating data")
                val validatedData = validate(template, map!!)
                // the data validation was consistent, so now the merging can be
                // applied
                status(true)
                line("Merging template and data")
                val merged = mergeTemplate(template, validatedData, output!!,
                        cmap)
                status(true)
                println()
                println("Done! Enjoy your template!")
                println("Written: " + getSize(merged))
            } catch (e: InvalidTemplateException) {
                status(false)
                error(e)
                exit = -1
            }
        }
        // the exit status is returned, denoting whether the application was able
        // to merge both template and data accordingly
        return exit
    }

    /**
     * Ensures the data map is never pointed to a null reference.
     */
    private fun ensureMap() {
        if (!has(map)) {
            map = mutableMapOf()
        }
    }

    /**
     * Gets the file size in a human readable format.
     *
     * @param bytes The file size, in bytes.
     * @return The file size in a human readable format.
     */
    @Suppress("MagicNumber")
    private fun getSize(bytes: Long): String {
        return if (bytes < 1024) {
            "$bytes B"
        } else {
            val exponent = (ln(bytes.toDouble()) / ln(1024.0)).toInt()
            "%.1f %cB".format(bytes / 1024.0.pow(exponent.toDouble()),
                    "KMGTPE"[exponent - 1])
        }
    }

    /**
     * Ensures the first parameter is not null, or sets it to the second one.
     *
     * @param T The type.
     * @param first First parameter.
     * @param second Second parameter.
     * @return Either the first or the second one.
     */
    private fun <T> ensure(first: T, second: T): T {
        return if (!has(first)) second else first
    }

    /**
     * Checks whether the object exists.
     *
     * @param obj The object.
     * @return Boolean value indicating whether the object exists.
     */
    private fun has(obj: Any?): Boolean {
        return obj != null
    }
}
