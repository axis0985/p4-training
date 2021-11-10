// Use V1Model as P4 Pipeline Architecture
#include <core.p4>
#include <v1model.p4>

#include "headers.p4"
#include "parsers.p4"
#include "checksum.p4"

control ingress_block(inout headers_t hdr,
                      inout local_metadata_t local_metadata,
                      inout standard_metadata_t standard_metadata) {
    // To drop the packet
    // mark_to_drop(standard_metadata);

    // To forward the packet through specified port:
    // standard_metadata.egress_spec = port;
    // port_id is 9 bits long

    // define your table here
    // forwarding should be done in ingress

    apply {
        // Don't forget to apply table
    }
}

control egress_block(inout headers_t hdr,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {
    apply {

    }
}
// V1Model: parser > checksum > ingress > PRE/TM > egress > checksum > deparser
V1Switch(ingress_parser(),
         ingress_checksum_validation(),
         ingress_block(),
         egress_block(),
         egress_checksum_recalc(),
         egress_deparser()) main;

