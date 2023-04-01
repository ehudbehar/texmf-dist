// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model

import com.moandjiezana.toml.Toml
import java.nio.file.Path
import org.islandoftex.texplate.exceptions.InvalidTemplateException

/**
 * The template model.
 *
 * @version 1.0
 * @since 1.0
 */
data class Template(
    /**
     * Name of the template
     */
    val name: String? = null,
    /**
     * Description of the template
     */
    val description: String? = null,
    /**
     * List of authors who wrote the template
     */
    val authors: List<String> = listOf(),
    /**
     * List of requirements for the template
     */
    val requirements: List<String> = listOf(),
    /**
     * The document to be configured
     */
    val document: String? = null,
    /**
     * The map handlers
     */
    val handlers: Map<String, String> = mapOf()
) {
    /**
     * Checks whether the template is valid.
     *
     * @return A boolean value indicating whether the template is valid.
     */
    private val isValid: Boolean
        get() = !(name == null || description == null ||
                document == null || name.isBlank() ||
                description.isBlank() || authors.isEmpty() ||
                document.isBlank())

    companion object {
        /**
         * Reads the template from the provided path.
         *
         * @param path The path to the template file.
         * @return The template object from the provided path.
         * @throws InvalidTemplateException The template is invalid.
         */
        @JvmStatic
        @Throws(InvalidTemplateException::class)
        fun fromPath(path: Path): Template {
            val template: Template
            // the exception message, in case the conversion fails or if there are
            // missing elements from the template
            val message = ("The provided template file looks invalid. Please " +
                    "make sure the template has a valid syntax and try again. ")
            template = try {
                Toml().read(path.toFile()).to(Template::class.java)
            } catch (exception: IllegalStateException) {
                throw InvalidTemplateException(message + "In this particular " +
                        "scenario, there is a possibility that the template " +
                        "file does not follow the TOML specification. Please " +
                        "refer to the user manual for further details and a " +
                        "possible fix. Also, the raised exception message can " +
                        "give us some hints on what happened.", exception)
            }
            // the conversion hasn't failed, but we need to check whether the
            // template is valid
            return if (template.isValid) {
                template
            } else {
                throw InvalidTemplateException(message + "Specifically, some " +
                        "mandatory fields are either absent or empty in the " +
                        "template file. It is quite important to strictly " +
                        "follow the template specification, as detailed in the " +
                        "user manual, or the tool will not work at all.")
            }
        }
    }
}
