// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model

import com.moandjiezana.toml.Toml
import java.nio.file.Path
import org.islandoftex.texplate.exceptions.InvalidTemplateException

/**
 * The configuration model.
 *
 * @version 1.0
 * @since 1.0
 */
data class Configuration(
    /**
     * The template of the template.
     */
    val template: String? = null,
    /**
     * Map of variables for the configuration.
     */
    val map: Map<String, Any> = mapOf()
) {
    /**
     * Whether the configuration is valid.
     */
    private val isValid: Boolean
        get() = template != null

    companion object {
        /**
         * Reads the configuration from path.
         *
         * @param path The path.
         * @return Configuration.
         * @throws InvalidTemplateException The configuration is invalid.
         */
        @Throws(InvalidTemplateException::class)
        fun fromPath(path: Path): Configuration {
            val configuration: Configuration
            val message = ("The provided configuration file looks invalid. " +
                    "Please make sure the configuration has a valid syntax and " +
                    "try again. ")
            configuration = try {
                // gets the configuration
                Toml().read(path.toFile()).to(Configuration::class.java)
            } catch (exception: IllegalStateException) {
                // the configuration seems invalid
                throw InvalidTemplateException(message + "In this particular " +
                        "scenario, there is a possibility that the configuration " +
                        "file does not follow the TOML specification. Please " +
                        "refer to the user manual for further details and a " +
                        "possible fix. Also, the raised exception message can " +
                        "give us some hints on what happened.", exception)
            }
            return if (configuration.isValid) {
                configuration
            } else {
                throw InvalidTemplateException(message + "Specifically, some " +
                        "mandatory fields are either absent or empty in the " +
                        "configuration file. It is quite important to strictly " +
                        "follow the configuration specification, as detailed in " +
                        "the user manual, or the tool will not work at all.")
            }
        }
    }
}
