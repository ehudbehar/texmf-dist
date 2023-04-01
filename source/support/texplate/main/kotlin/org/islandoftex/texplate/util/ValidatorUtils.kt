// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.util

import org.islandoftex.texplate.exceptions.InvalidKeySetException
import org.islandoftex.texplate.model.Template

/**
 * Helper methods for validation.
 *
 * @version 1.0
 * @since 1.0
 */
object ValidatorUtils {
    /**
     * Validates the data map based on the template requirements.
     *
     * @param template The template.
     * @param map The data map.
     * @return A boolean value indicating whether the data map is valid.
     */
    private fun validateRequirements(
        template: Template,
        map: Map<String, String>
    ): Boolean {
        return template.requirements.isNullOrEmpty() ||
                template.requirements.containsAll(map.keys)
    }

    /**
     * Validates the template pattern and the data map and throws an exception
     * in case of failure.
     *
     * @param template The template.
     * @param map The data map.
     * @return The data map.
     * @throws InvalidKeySetException There are invalid keys in the map.
     */
    @JvmStatic
    @Throws(InvalidKeySetException::class)
    fun validate(
        template: Template,
        map: Map<String, String>
    ): Map<String, String> {
        // for starters, we try to validate the template requirements
        return if (validateRequirements(template, map)) {
            map
        } else {
            throw InvalidKeySetException("The provided map does not " +
                    "contain all the keys required by the chosen " +
                    "template. Make sure to define such keys and try " +
                    "again. Check the user manual for further details.")
        }
    }
}
