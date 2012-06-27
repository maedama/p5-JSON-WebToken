use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    Crypt::OpenSSL::RSA
    Crypt::OpenSSL::Bignum
);
use Test::Mock::Guard qw(mock_guard);
use JSON::XS;
use JSON::WebToken;

my $header = pack 'C*' => @{ [123, 34, 97, 108, 103, 34, 58, 34, 82, 83, 50, 53, 54, 34, 125] };

my $claims = pack 'C*' => @{ [
    123, 34,  105, 115, 115, 34,  58,  34,  106, 111, 101, 34,  44,  13,
    10,  32,  34,  101, 120, 112, 34,  58,  49,  51,  48,  48,  56,  49,
    57,  51,  56,  48,  44,  13,  10,  32,  34,  104, 116, 116, 112, 58,
    47,  47,  101, 120, 97,  109, 112, 108, 101, 46,  99,  111, 109, 47,
    105, 115, 95,  114, 111, 111, 116, 34,  58,  116, 114, 117, 101, 125
] };

my $singing_input = pack 'C*' => @{ [
    101, 121, 74,  104, 98,  71, 99,  105, 79,  105, 74,  83,  85,  122,
    73,  49,  78,  105, 74,  57, 46,  101, 121, 74,  112, 99,  51,  77,
    105, 79,  105, 74,  113, 98, 50,  85,  105, 76,  65,  48,  75,  73,
    67,  74,  108, 101, 72,  65, 105, 79,  106, 69,  122, 77,  68,  65,
    52,  77,  84,  107, 122, 79, 68,  65,  115, 68,  81,  111, 103, 73,
    109, 104, 48,  100, 72,  65, 54,  76,  121, 57,  108, 101, 71,  70,
    116, 99,  71,  120, 108, 76, 109, 78,  118, 98,  83,  57,  112, 99,
    49,  57,  121, 98,  50,  57, 48,  73,  106, 112, 48,  99,  110, 86,
    108, 102, 81
] };

my $rsa = do {
    my $n = pack 'C*' => @{ [
        161, 248, 22,  10,  226, 227, 201, 180, 101, 206, 141, 45,  101, 98,
        99,  54,  43,  146, 125, 190, 41,  225, 240, 36,  119, 252, 22,  37,
        204, 144, 161, 54,  227, 139, 217, 52,  151, 197, 182, 234, 99,  221,
        119, 17,  230, 124, 116, 41,  249, 86,  176, 251, 138, 143, 8,   154,
        220, 75,  105, 137, 60,  193, 51,  63,  83,  237, 208, 25,  184, 119,
        132, 37,  47,  236, 145, 79,  228, 133, 119, 105, 89,  75,  234, 66,
        128, 211, 44,  15,  85,  191, 98,  148, 79,  19,  3,   150, 188, 110,
        155, 223, 110, 189, 210, 189, 163, 103, 142, 236, 160, 198, 104, 247,
        1,   179, 141, 191, 251, 56,  200, 52,  44,  226, 254, 109, 39,  250,
        222, 74,  90,  72,  116, 151, 157, 212, 185, 207, 154, 222, 196, 199,
        91,  5,   133, 44,  44,  15,  94,  248, 165, 193, 117, 3,   146, 249,
        68,  232, 237, 100, 193, 16,  198, 182, 71,  96,  154, 164, 120, 58,
        235, 156, 108, 154, 215, 85,  49,  48,  80,  99,  139, 131, 102, 92,
        111, 111, 122, 130, 163, 150, 112, 42,  31,  100, 27,  130, 211, 235,
        242, 57,  34,  25,  73,  31,  182, 134, 135, 44,  87,  22,  245, 10,
        248, 53,  141, 154, 139, 157, 23,  195, 64,  114, 143, 127, 135, 216,
        154, 24,  216, 252, 171, 103, 173, 132, 89,  12,  46,  207, 117, 147,
        57,  54,  60,  7,   3,   77,  111, 96,  111, 158, 33,  224, 84,  86,
        202, 229, 233, 161
    ] };
    my $e = pack 'C*' => @{ [1, 0, 1] };
    my $d = pack 'C*' => @{ [
        18,  174, 113, 164, 105, 205, 10,  43,  195, 126, 82,  108, 69,  0,
        87,  31,  29,  97,  117, 29,  100, 233, 73,  112, 123, 98,  89,  15,
        157, 11,  165, 124, 150, 60,  64,  30,  63,  207, 47,  44,  211, 189,
        236, 136, 229, 3,   191, 198, 67,  155, 11,  40,  200, 47,  125, 55,
        151, 103, 31,  82,  19,  238, 216, 193, 90,  37,  216, 213, 206, 160,
        2,   94,  227, 171, 46,  139, 127, 121, 33,  111, 198, 59,  234, 86,
        39,  83,  180, 6,   68,  198, 161, 81,  39,  217, 178, 149, 69,  64,
        160, 187, 225, 163, 5,   86,  152, 45,  78,  159, 222, 95,  100, 37,
        241, 77,  75,  113, 52,  65,  181, 93,  199, 59,  155, 74,  237, 204,
        146, 172, 227, 146, 126, 55,  245, 125, 12,  253, 94,  117, 129, 250,
        81,  44,  143, 73,  97,  169, 235, 11,  128, 248, 168, 7,   70,  114,
        138, 85,  255, 70,  71,  31,  52,  37,  6,   59,  157, 83,  100, 47,
        94,  222, 30,  132, 214, 19,  8,   26,  250, 92,  34,  208, 81,  40,
        91,  214, 59,  148, 59,  86,  93,  137, 138, 5,   104, 84,  19,  229,
        60,  60,  108, 101, 37,  255, 31,  227, 78,  61,  220, 112, 240, 213,
        100, 80,  253, 164, 139, 161, 46,  16,  78,  157, 235, 159, 184, 24,
        129, 225, 196, 189, 242, 93,  146, 71,  244, 80,  200, 101, 146, 121,
        104, 231, 115, 52,  244, 65,  79,  117, 167, 80,  225, 57,  84,  110,
        58,  138, 115, 157
    ] };

    my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters(map {
        Crypt::OpenSSL::Bignum->new_from_bin($_)
    } $n, $e, $d);
};

my $S = pack 'C*' => @{ [
    112, 46,  33,  137, 67,  232, 143, 209, 30,  181, 216, 45,  191, 120,
    69,  243, 65,  6,   174, 27,  129, 255, 247, 115, 17,  22,  173, 209,
    113, 125, 131, 101, 109, 66,  10,  253, 60,  150, 238, 221, 115, 162,
    102, 62,  81,  102, 104, 123, 0,   11,  135, 34,  110, 1,   135, 237,
    16,  115, 249, 69,  229, 130, 173, 252, 239, 22,  216, 90,  121, 142,
    232, 198, 109, 219, 61,  184, 151, 91,  23,  208, 148, 2,   190, 237,
    213, 217, 217, 112, 7,   16,  141, 178, 129, 96,  213, 248, 4,   12,
    167, 68,  87,  98,  184, 31,  190, 127, 249, 217, 46,  10,  231, 111,
    36,  242, 91,  51,  187, 230, 244, 74,  230, 30,  177, 4,   10,  203,
    32,  4,   77,  62,  249, 18,  142, 212, 1,   48,  121, 91,  212, 189,
    59,  65,  238, 202, 208, 102, 171, 101, 25,  129, 253, 228, 141, 247,
    127, 55,  45,  195, 139, 159, 175, 221, 59,  239, 177, 139, 93,  163,
    204, 60,  46,  176, 47,  158, 58,  65,  214, 18,  202, 173, 21,  145,
    18,  115, 160, 95,  35,  185, 232, 56,  250, 175, 132, 157, 105, 132,
    41,  239, 90,  30,  136, 121, 130, 54,  195, 212, 14,  96,  69,  34,
    165, 68,  200, 242, 122, 122, 45,  184, 6,   99,  209, 108, 247, 202,
    234, 86,  222, 64,  92,  178, 33,  90,  69,  178, 194, 85,  102, 181,
    90,  193, 167, 72,  160, 112, 223, 200, 163, 42,  70,  149, 67,  208,
    25,  238, 251, 71
] };

$rsa->use_sha256_hash;
is $rsa->sign($singing_input), $S;
ok $rsa->verify($singing_input, $S);

my $guard = mock_guard(
    'JSON::WebToken' => {
        encode_json => sub {
            my $array = [$header, $claims];
            sub { shift @$array };
        }->(),
    },
    'Crypt::OpenSSL::RSA' => {
        new_private_key => $rsa,
    },
);

my $public_key = $rsa->get_public_key_string;
my $jwt = JSON::WebToken->encode({}, 'dummy', 'RS256');
is $jwt, join('.',
    (
        'eyJhbGciOiJSUzI1NiJ9'
    ),
    (
        'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFt'.
        'cGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
    ),
    (
        'cC4hiUPoj9Eetdgtv3hF80EGrhuB__dzERat0XF9g2VtQgr9PJbu3XOiZj5RZmh7'.
        'AAuHIm4Bh-0Qc_lF5YKt_O8W2Fp5jujGbds9uJdbF9CUAr7t1dnZcAcQjbKBYNX4'.
        'BAynRFdiuB--f_nZLgrnbyTyWzO75vRK5h6xBArLIARNPvkSjtQBMHlb1L07Qe7K'.
        '0GarZRmB_eSN9383LcOLn6_dO--xi12jzDwusC-eOkHWEsqtFZESc6BfI7noOPqv'.
        'hJ1phCnvWh6IeYI2w9QOYEUipUTI8np6LbgGY9Fs98rqVt5AXLIhWkWywlVmtVrB'.
        'p0igcN_IoypGlUPQGe77Rw'
    ),
);

my $got = JSON::WebToken->decode($jwt, $public_key);
is_deeply $got, decode_json($claims);

done_testing;
