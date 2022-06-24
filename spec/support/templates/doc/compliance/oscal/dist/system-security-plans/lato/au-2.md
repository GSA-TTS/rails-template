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
sort-id: au-02
---

# au-2 - \[\] Event Logging

## Control Statement

- \[a.\] Identify the types of events that the system is capable of logging in support of the audit function: (1) successful and unsuccessful account logon events, account management events, object access, policy change, privilege functions, process tracking, and system events (2) Web applications should log all administrator activity, authentication checks, authorization checks, data deletions, data access, data changes, and permission changes (3) for technologies with limited auditing features, the capabilities will be recommended by the GSA S/SO or Contractor, based on an industry source such as vendor guidance or Center for Internet Security benchmark, and approved by the GSA CISO and AO;

- \[b.\] Coordinate the event logging function with other organizational entities requiring audit-related information to guide and inform the selection criteria for events to be logged;

- \[c.\] Specify the following event types for logging within the system: (1) audit configuration requirements as documented in applicable GSA IT Security Technical Guides and Standards (i.e., hardening and technology implementation guides) (2) for web applications see GSA IT Security Procedural Guide 07-35, Section 2.8.10, What to Log (3) for technologies where a Technical Guide and Standard does not exist, events from an industry source such as vendor guidance or Center for Internet Security benchmark, recommended by the GSA S/SO or Contractor and approved by the GSA CISO and AO;

- \[d.\] Provide a rationale for why the event types selected for logging are deemed to be adequate to support after-the-fact investigations of incidents; and

- \[e.\] Review and update the event types selected for logging annually or whenever there is a change in the system’s threat environment as communicated by the GSA S/SO AO or the GSA OCISO.

## Control guidance

An event is an observable occurrence in a system. The types of events that require logging are those events that are significant and relevant to the security of systems and the privacy of individuals. Event logging also supports specific monitoring and auditing needs. Event types include password changes, failed logons or failed accesses related to systems, security or privacy attribute changes, administrative privilege usage, PIV credential usage, data action changes, query parameters, or external credential usage. In determining the set of event types that require logging, organizations consider the monitoring and auditing appropriate for each of the controls to be implemented. For completeness, event logging includes all protocols that are operational and supported by the system.

To balance monitoring and auditing requirements with other system needs, event logging requires identifying the subset of event types that are logged at a given point in time. For example, organizations may determine that systems need the capability to log every file access successful and unsuccessful, but not activate that capability except for specific circumstances due to the potential burden on system performance. The types of events that organizations desire to be logged may change. Reviewing and updating the set of logged events is necessary to help ensure that the events remain relevant and continue to support the needs of the organization. Organizations consider how the types of logging events can reveal information about individuals that may give rise to privacy risk and how best to mitigate such risks. For example, there is the potential to reveal personally identifiable information in the audit trail, especially if the logging event is based on patterns or time of usage.

Event logging requirements, including the need to log specific event types, may be referenced in other controls and control enhancements. These include [AC-2(4)](#ac-2.4), [AC-3(10)](#ac-3.10), [AC-6(9)](#ac-6.9), [AC-17(1)](#ac-17.1), [CM-3f](#cm-3_smt.f), [CM-5(1)](#cm-5.1), [IA-3(3)(b)](#ia-3.3_smt.b), [MA-4(1)](#ma-4.1), [MP-4(2)](#mp-4.2), [PE-3](#pe-3), [PM-21](#pm-21), [PT-7](#pt-7), [RA-8](#ra-8), [SC-7(9)](#sc-7.9), [SC-7(15)](#sc-7.15), [SI-3(8)](#si-3.8), [SI-4(22)](#si-4.22), [SI-7(8)](#si-7.8) , and [SI-10(1)](#si-10.1) . Organizations include event types that are required by applicable laws, executive orders, directives, policies, regulations, standards, and guidelines. Audit records can be generated at various levels, including at the packet level as information traverses the network. Selecting the appropriate level of event logging is an important part of a monitoring and auditing capability and can identify the root causes of problems. When defining event types, organizations consider the logging necessary to cover related event types, such as the steps in distributed, transaction-based processes and the actions that occur in service-oriented architectures.

## Control assessment-objective

(1) successful and unsuccessful account logon events, account management events, object access, policy change, privilege functions, process tracking, and system events (2) Web applications should log all administrator activity, authentication checks, authorization checks, data deletions, data access, data changes, and permission changes (3) for technologies with limited auditing features, the capabilities will be recommended by the GSA S/SO or Contractor, based on an industry source such as vendor guidance or Center for Internet Security benchmark, and approved by the GSA CISO and AO that the system is capable of logging are identified in support of the audit logging function;
the event logging function is coordinated with other organizational entities requiring audit-related information to guide and inform the selection criteria for events to be logged;
event types (subset of AU-02_ODP[01]) are specified for logging within the system;
the specified event types are logged within the system frequency or situation;
a rationale is provided for why the event types selected for logging are deemed to be adequate to support after-the-fact investigations of incidents;
the event types selected for logging are reviewed and updated annually or whenever there is a change in the system’s threat environment as communicated by the GSA S/SO AO or the GSA OCISO.

______________________________________________________________________

## What is the solution and how is it implemented?

<!-- Please leave this section blank and enter implementation details in the parts below. -->

______________________________________________________________________

## Implementation a.

Add control implementation description here for item au-2_smt.a

______________________________________________________________________

## Implementation b.

Add control implementation description here for item au-2_smt.b

______________________________________________________________________

## Implementation c.

Add control implementation description here for item au-2_smt.c

______________________________________________________________________

## Implementation d.

Add control implementation description here for item au-2_smt.d

______________________________________________________________________

## Implementation e.

Add control implementation description here for item au-2_smt.e

______________________________________________________________________
