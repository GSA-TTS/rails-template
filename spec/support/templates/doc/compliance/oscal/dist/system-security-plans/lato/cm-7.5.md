---
implementation-status:
  - c-not-implemented
  - c-partially-implemented
  - c-planned
  - c-alternative-implementation
  - c-not-applicable
control-origination:
  - c-inherited
  - c-common-control
  - c-hybrid-control
  - c-system-specific-control
sort-id: cm-07.05
---

# cm-7.5 - \[\] Authorized Software — Allow-by-exception

## Control Statement

- \[(a)\] Identify GSA S/SO or Contractor recommended software programs authorized to execute on the information system as approved by the GSA CISO and AO;

- \[(b)\] Employ a deny-all, permit-by-exception policy to allow the execution of authorized software programs on the system; and

- \[(c)\] Review and update the list of authorized software programs annually as part of SSPP update.

## Control guidance

Authorized software programs can be limited to specific versions or from a specific source. To facilitate a comprehensive authorized software process and increase the strength of protection for attacks that bypass application level authorized software, software programs may be decomposed into and monitored at different levels of detail. These levels include applications, application programming interfaces, application modules, scripts, system processes, system services, kernel functions, registries, drivers, and dynamic link libraries. The concept of permitting the execution of authorized software may also be applied to user actions, system ports and protocols, IP addresses/ranges, websites, and MAC addresses. Organizations consider verifying the integrity of authorized software programs using digital signatures, cryptographic checksums, or hash functions. Verification of authorized software can occur either prior to execution or at system startup. The identification of authorized URLs for websites is addressed in [CA-3(5)](#ca-3.5) and [SC-7](#sc-7).

## Control assessment-objective

GSA S/SO or Contractor recommended software programs authorized to execute on the information system as approved by the GSA CISO and AO are identified;
a deny-all, permit-by-exception policy to allow the execution of authorized software programs on the system is employed;
the list of authorized software programs is reviewed and updated annually as part of SSPP update.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation (a)

Add control implementation description here for item cm-7.5_smt.a

______________________________________________________________________

## Implementation (b)

Add control implementation description here for item cm-7.5_smt.b

______________________________________________________________________

## Implementation (c)

Add control implementation description here for item cm-7.5_smt.c

______________________________________________________________________
