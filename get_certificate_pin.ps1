# TLU Certificate PIN Extraction Script
# For Windows PowerShell with OpenSSL 3.6.0

Write-Host "Downloading TLU certificate..." -ForegroundColor Green

# Step 1: Download and save certificate properly
$openSSLOutput = echo "quit" | openssl s_client -connect sinhvien1.tlu.edu.vn:443 -showcerts 2>$null
$openSSLOutput | openssl x509 -outform DER -out tlu_cert.der

Write-Host "Certificate saved to tlu_cert.der" -ForegroundColor Green

# Step 2: Verify certificate was created
if (Test-Path "tlu_cert.der") {
    Write-Host "Certificate file verified" -ForegroundColor Green
} else {
    Write-Host "ERROR: Certificate file not created!" -ForegroundColor Red
    exit 1
}

# Step 3: Extract public key in DER format
Write-Host "Extracting PIN..." -ForegroundColor Green

# Save public key to temporary file
openssl x509 -inform DER -in tlu_cert.der -noout -pubkey | `
    openssl pkey -pubin -outform DER > pubkey.der

# Calculate hash and save to file
openssl dgst -sha256 -binary pubkey.der > hash.bin

# Read the binary hash file
$hash = [System.IO.File]::ReadAllBytes("hash.bin")

# Step 4: Convert to Base64
$pin = [Convert]::ToBase64String($hash)

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Your TLU Certificate PIN (SHA-256):" -ForegroundColor Green
Write-Host $pin -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 6: Save to file
$pin | Out-File "tlu_certificate_pin.txt" -Encoding UTF8
Write-Host "PIN saved to: tlu_certificate_pin.txt" -ForegroundColor Green

# Step 7: Copy to clipboard
$pin | Set-Clipboard
Write-Host "PIN copied to clipboard!" -ForegroundColor Green

# Cleanup temporary files
Remove-Item -Path "pubkey.der" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "hash.bin" -Force -ErrorAction SilentlyContinue
