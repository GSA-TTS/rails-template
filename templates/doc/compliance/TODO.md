Compliance Tasks
================

This file contains a list of some tasks that can make your compliance journey a bit easier.

These instructions assume that your application is being hosted on cloud.gov.

Egress Spaces
-------------

If your application requires outbound communication to services outside of cloud.gov:

1. `bin/rails g rails_template18f:public_egress`
1. Document this use under the SC-7 security control

Log Drains
----------

Follow these directions to send your logs to an external consumer, such an S3 bucket for GSA SOC to ingest or New Relic

1. Deploy the [logstash-shipper](https://github.com/GSA/datagov-logstack#setup) app in a management space. The management space could be its own space, or `<env>-egress`
1. Deploy a [space-drain](https://github.com/GSA/datagov-logstack/blob/main/create-space-drain.sh) so that any app deployed to that space automatically has its logs shipped

Drift Detection
---------------

1. Deploy [Watchtower](https://github.com/18F/watchtower) for drift detection

Future Good Ideas
-----------------

Other things that would be useful, but without decent implementations yet:

* For RA-5, deploy a Monit sidecar buildpack to restart app if any anomalys are detected
