# Secure webhook example

This example configures a **secure webhook** receiver, where Azure Monitor authenticates to the
receiving endpoint with a Microsoft Entra token instead of a shared secret. No credential material
is written to the configuration or to Terraform state for this receiver type.

The receiver references a Microsoft Entra application registration by service principal object ID
and Application ID URI. Those objects live in Microsoft Graph, not in Azure Resource Manager, so
they cannot be created with the `Azure/azapi` provider and are therefore **not** created here.

## This example is excluded from end-to-end tests

The directory contains a `.e2eignore` file. The `object_id` and `identifier_uri` values are
synthetic placeholders, and a real deployment additionally requires the Entra application to have
been granted access by Azure Monitor. Because those prerequisites cannot be provisioned through
ARM, this example is intentionally not deployed by the end-to-end test suite.

To use it, replace the synthetic values with the object ID and Application ID URI of an
application registration in your own tenant, and complete the secure webhook onboarding steps for
Azure Monitor.
