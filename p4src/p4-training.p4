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
    action fwd(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    action fwd_decap(bit<9> port) {
        fwd(port);
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtp_u.setInvalid();
        hdr.gtp_u_options.setInvalid();
    }

    action fwd_encap(bit<9> port, bit<32> teid) {
        fwd(port);
        local_metadata.encap_teid = teid;
        local_metadata.encap_flag = 1;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    table arp_table {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            fwd;
            drop;
        }
        const default_action = drop;
        const entries = {
            9w1: fwd(2);
            9w2: fwd(1);
        }
    }

    table fwd_table {
        key = {
            hdr.ipv4.dst_addr: exact;
        }
        actions = {
            fwd;
            fwd_decap;
            fwd_encap;
            drop;
        }
        size = 512;
        const default_action = drop();
    }

    apply {
        // Don't forget to apply table
        if (hdr.arp.isValid()) {
            arp_table.apply();
        } else {
            fwd_table.apply();
        }
    }
}

control egress_block(inout headers_t hdr,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {
    action encap() {
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.dscp = hdr.ipv4.dscp;
        hdr.inner_ipv4.ecn = hdr.ipv4.ecn;
        hdr.inner_ipv4.len = hdr.ipv4.len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;

        hdr.ipv4.ttl = DEFAULT_IPV4_TTL;
        hdr.ipv4.len = hdr.ipv4.len + (IPV4_HDR_SIZE + UDP_HDR_SIZE + GTP_HDR_SIZE);
        hdr.ipv4.protocol = IP_PROTO_UDP;

        hdr.udp.len = hdr.inner_ipv4.len + GTP_HDR_SIZE + UDP_HDR_SIZE;
        hdr.udp.checksum = 0;
        hdr.udp.src_port = 2152;
        hdr.udp.dst_port = 2152;
        
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = GTPU_VERSION;
        hdr.gtp_u.pt = GTP_PROTOCOL_TYPE_GTP;
        hdr.gtp_u.spare = 0;
        hdr.gtp_u.ex_flag = 0;
        hdr.gtp_u.seq_flag = 0;
        hdr.gtp_u.npdu_flag = 0;
        hdr.gtp_u.msgtype = GTP_GPDU;
        hdr.gtp_u.msglen = hdr.inner_ipv4.len;
        hdr.gtp_u.teid = local_metadata.encap_teid;
    }
    
    apply {
        if (local_metadata.encap_flag == 1) {
            encap();
        }
    }
}
// V1Model: parser > checksum > ingress > PRE/TM > egress > checksum > deparser
V1Switch(ingress_parser(),
         ingress_checksum_validation(),
         ingress_block(),
         egress_block(),
         egress_checksum_recalc(),
         egress_deparser()) main;

