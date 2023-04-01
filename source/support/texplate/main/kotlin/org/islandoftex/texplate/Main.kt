// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate

import kotlin.system.exitProcess
import org.islandoftex.texplate.util.MessageUtils
import picocli.CommandLine

/**
 * Main method. Note that it simply passes the control to the template
 * processing class.
 *
 * @param args The command line arguments.
 */
fun main(args: Array<String>) {
    // draw the application logo in the terminal (please have fixed fonts
    // in your terminal for a nice display)
    MessageUtils.drawLogo()
    // calls the command line processing method and performs the actual
    // application logic
    @Suppress("SpreadOperator")
    val exitCode = CommandLine(TemplateProcessing()).execute(*args)
    exitProcess(exitCode)
}
