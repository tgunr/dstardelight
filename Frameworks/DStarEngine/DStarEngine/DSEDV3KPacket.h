

#ifndef DSEDV3KPacket_h
#define DSEDV3KPacket_h

#define DV3K_TYPE_CONTROL 0x00
#define DV3K_TYPE_AMBE 0x01
#define DV3K_TYPE_AUDIO 0x02

static const unsigned char DV3K_START_BYTE   = 0x61;

static const unsigned char DV3K_CONTROL_RATEP  = 0x0A;
static const unsigned char DV3K_CONTROL_PRODID = 0x30;
static const unsigned char DV3K_CONTROL_VERSTRING = 0x31;
static const unsigned char DV3K_CONTROL_RESET = 0x33;
static const unsigned char DV3K_CONTROL_READY = 0x39;
static const unsigned char DV3K_CONTROL_CHANFMT = 0x15;

static const unsigned char DV3K_AMBE_FIELD_CMODE = 0x02;
static const unsigned char DV3K_AMBE_FIELD_TONE = 0x08;
static const unsigned char DV3K_AMBE_FIELD_CHAND = 0x01;

static const unsigned char DV3K_AUDIO_FIELD_SPEECHD = 0x00;

static const char ratep_values[12] = { 0x01, 0x30, 0x07, 0x63, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48 };

//  The size of a dv3k header is the start byte, plus header size plus the payload length
#define dv3k_packet_size(a) (1 + sizeof((a).header) + ntohs((a).header.payload_length))

#pragma pack(push, 1)
struct dv3k_packet {
    unsigned char start_byte;
    struct {
        unsigned short payload_length;
        unsigned char packet_type;
    } header;
    union {
        struct {
            unsigned char field_id;
            union {
                char prodid[16];
                char ratep[12];
                char version[48];
                short chanfmt;
            } data;
        } ctrl;
        struct {
            unsigned char field_id;
            unsigned char num_samples;
            short samples[160];
            unsigned char cmode_field_id;
            short cmode_value;
        } audio;
        struct {
            struct {
                unsigned char field_id;
                unsigned char num_bits;
                unsigned char data[9];
            } data;
            struct {
                unsigned char field_id;
                unsigned short value;
            } cmode;
            struct {
                unsigned char field_id;
                unsigned char tone;
                unsigned char amplitude;
            } tone;
        } ambe;
    } payload;
};
#pragma pack(pop)

#endif
