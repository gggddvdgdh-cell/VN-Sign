import datetime, uuid, base64, ipaddress, os
from cryptography import x509
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import pkcs12

# 1. Root CA
ca_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
ca_name = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, 'VN-Sign Local Root CA'),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, 'VN-Sign Corporation'),
    x509.NameAttribute(NameOID.COUNTRY_NAME, 'VN'),
])
now = datetime.datetime.now(datetime.timezone.utc)
ca_cert = (
    x509.CertificateBuilder()
    .subject_name(ca_name)
    .issuer_name(ca_name)
    .public_key(ca_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - datetime.timedelta(days=1))
    .not_valid_after(now + datetime.timedelta(days=7300)) # 20 years
    .add_extension(x509.BasicConstraints(ca=True, path_length=None), critical=True)
    .add_extension(
        x509.KeyUsage(
            digital_signature=True,
            content_commitment=False,
            key_encipherment=False,
            data_encipherment=False,
            key_agreement=False,
            key_cert_sign=True,
            crl_sign=True,
            encipher_only=False,
            decipher_only=False,
        ),
        critical=True,
    )
    .add_extension(
        x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()),
        critical=False,
    )
    .sign(ca_key, hashes.SHA256())
)

# 2. Server Cert for 127.0.0.1 and localhost
server_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
server_name = x509.Name([
    x509.NameAttribute(NameOID.COMMON_NAME, '127.0.0.1'),
    x509.NameAttribute(NameOID.ORGANIZATION_NAME, 'VN-Sign Local OTA Server'),
    x509.NameAttribute(NameOID.COUNTRY_NAME, 'VN'),
])
server_cert = (
    x509.CertificateBuilder()
    .subject_name(server_name)
    .issuer_name(ca_name)
    .public_key(server_key.public_key())
    .serial_number(x509.random_serial_number())
    .not_valid_before(now - datetime.timedelta(days=1))
    .not_valid_after(now + datetime.timedelta(days=3650)) # 10 years
    .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
    .add_extension(
        x509.SubjectAlternativeName([
            x509.IPAddress(ipaddress.IPv4Address('127.0.0.1')),
            x509.DNSName('localhost'),
            x509.DNSName('vnsign.local'),
        ]),
        critical=False,
    )
    .add_extension(
        x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH]),
        critical=False,
    )
    .add_extension(
        x509.KeyUsage(
            digital_signature=True,
            content_commitment=False,
            key_encipherment=True,
            data_encipherment=False,
            key_agreement=False,
            key_cert_sign=False,
            crl_sign=False,
            encipher_only=False,
            decipher_only=False,
        ),
        critical=True,
    )
    .sign(ca_key, hashes.SHA256())
)

# 3. Create server.p12 (password: vnsign)
p12_bytes = pkcs12.serialize_key_and_certificates(
    name=b'vnsign_server',
    key=server_key,
    cert=server_cert,
    cas=[ca_cert],
    encryption_algorithm=serialization.BestAvailableEncryption(b'vnsign'),
)

# 4. Create mobileconfig
ca_der = ca_cert.public_bytes(serialization.Encoding.DER)
ca_b64 = base64.b64encode(ca_der).decode('ascii')
ca_b64_formatted = '\n'.join([ca_b64[i:i+64] for i in range(0, len(ca_b64), 64)])

cert_uuid = str(uuid.uuid4()).upper()
profile_uuid = str(uuid.uuid4()).upper()

mobileconfig = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadCertificateFileName</key>
            <string>vnsign_root_ca.crt</string>
            <key>PayloadContent</key>
            <data>
{ca_b64_formatted}
            </data>
            <key>PayloadDescription</key>
            <string>Chứng chỉ gốc tin cậy nội bộ phục vụ cài đặt trực tiếp ứng dụng OTA HTTPS cho VN-Sign.</string>
            <key>PayloadDisplayName</key>
            <string>VN-Sign Local Root CA</string>
            <key>PayloadIdentifier</key>
            <string>com.vnsign.rootca.cert</string>
            <key>PayloadType</key>
            <string>com.apple.security.root</string>
            <key>PayloadUUID</key>
            <string>{cert_uuid}</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>Cài đặt hồ sơ này để iPhone tin cậy máy chủ nội bộ VN-Sign và cho phép cài đặt trực tiếp ứng dụng không cần máy tính.</string>
    <key>PayloadDisplayName</key>
    <string>VN-Sign Local CA Profile</string>
    <key>PayloadIdentifier</key>
    <string>com.vnsign.rootca.profile</string>
    <key>PayloadOrganization</key>
    <string>VN-Sign Corporation</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>{profile_uuid}</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>"""

target_dir = r'd:\VN-Sign\ios-app\VN-Sign\Resources'
os.makedirs(target_dir, exist_ok=True)

with open(os.path.join(target_dir, 'vnsign_server.p12'), 'wb') as f:
    f.write(p12_bytes)

with open(os.path.join(target_dir, 'VNSign_Root_CA.mobileconfig'), 'w', encoding='utf-8') as f:
    f.write(mobileconfig)

print('Generated vnsign_server.p12 and VNSign_Root_CA.mobileconfig successfully in Resources!')
