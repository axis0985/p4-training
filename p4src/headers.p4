#ifndef __HEADERS__
#define __HEADERS__

#include "defines.p4"

// Ethernet Header
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

// IPV4 Header
header ipv4_h {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

// ARP Header
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
}

// UDP Header
header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

// ICMP Header
header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header gtp_u_h {
    bit<3>  version;    /* version */
    bit<1>  pt;         /* protocol type */
    bit<1>  spare;      /* reserved */
    bit<1>  ex_flag;    /* whether there is an extension header optional field */
    bit<1>  seq_flag;   /* whether there is a Sequence Number optional field */
    bit<1>  npdu_flag;  /* whether there is a N-PDU number optional field */
    bit<8>  msgtype;    /* message type */
    bit<16> msglen;     /* length of the payload in octets */
    bit<32> teid;       /* tunnel endpoint id */
}

header gtp_u_options_h {
    bit<16> seq_num;
    bit<8>  n_pdu_num; 
    bit<8>  next_ext;
}

// TCP Header
header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<3> res;
    bit<3> ecn;
    bit<6> ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}
// user-defined packet headers stack
struct headers_t {
    // make your protocol stacks here
    ethernet_h eth;
    arp_h arp;
    ipv4_h ipv4;
    udp_h udp;
    tcp_h tcp;
    gtp_u_h gtp_u;
    gtp_u_h gtp_u_options;
    ipv4_h inner_ipv4;
}
// user-defined metadata
struct local_metadata_t {
    bit<32> encap_teid;
    bit<1> encap_flag;
}


#endif
