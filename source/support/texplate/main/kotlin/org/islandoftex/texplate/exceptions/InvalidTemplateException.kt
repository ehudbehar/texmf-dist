// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.exceptions

/**
 * Handles exceptions when the template is somehow invalid.
 *
 * @version 1.0
 * @since 1.0
 */
class InvalidTemplateException : Exception {
    constructor()

    /**
     * Constructor.
     *
     * @param message Message to be attached to the exception.
     */
    constructor(message: String?) : super(message)

    /**
     * Constructor.
     *
     * @param message Message to be attached to the exception.
     * @param cause The throwable cause to be forwarded.
     */
    constructor(message: String?, cause: Throwable?) : super(message, cause)
}
