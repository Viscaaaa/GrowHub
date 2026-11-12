<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kode OTP Verifikasi Ubah Password</title>
</head>
<body style="margin:0; padding:0; background-color:#f4f7f5; font-family:'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color:#142c14;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:32px 16px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px; background:#ffffff; border-radius:16px; border:1px solid #e5ece7; overflow:hidden; box-shadow:0 8px 24px rgba(20,44,20,0.06);">
                    <tr>
                        <td style="background:linear-gradient(135deg, #1e8c45 0%, #142c14 100%); padding:24px 28px; color:#ffffff;">
                            <div style="font-size:22px; font-weight:800; letter-spacing:-0.02em;">GrowHub</div>
                            <div style="font-size:12px; opacity:0.88; margin-top:4px; letter-spacing:0.04em; text-transform:uppercase;">Ramayana &amp; Co Learning Hub</div>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:28px;">
                            <p style="margin:0 0 12px; font-size:15px;">Halo <strong>{{ $user->name }}</strong> (NIP: {{ $user->nip }}),</p>
                            <p style="margin:0 0 20px; font-size:14px; line-height:1.6; color:#4a5d4e;">
                                Kami menerima permintaan untuk melakukan verifikasi keamanan sebelum mengubah password akun GrowHub Anda. Gunakan kode OTP berikut untuk melanjutkan:
                            </p>

                            <div style="background:#edf8f1; border:1px dashed #1e8c45; border-radius:12px; padding:18px; text-align:center; margin-bottom:20px;">
                                <div style="font-size:11px; text-transform:uppercase; letter-spacing:0.08em; color:#19773a; font-weight:700; margin-bottom:6px;">
                                    Kode OTP Anda
                                </div>
                                <div style="font-size:32px; font-weight:800; letter-spacing:8px; color:#142c14; font-family:Consolas, Monaco, monospace;">
                                    {{ $otpCode }}
                                </div>
                            </div>

                            <p style="margin:0 0 14px; font-size:13px; line-height:1.6; color:#4a5d4e;">
                                Kode OTP ini berlaku selama <strong>{{ $expiresMinutes }} menit</strong> dan hanya dapat digunakan satu kali.
                            </p>

                            <div style="background:#fff7e6; border:1px solid #fde68a; border-radius:10px; padding:12px 14px; font-size:12px; line-height:1.5; color:#92400e;">
                                <strong>Penting:</strong> Demi keamanan akun, jangan pernah membagikan kode OTP ini kepada siapa pun termasuk pihak yang mengaku sebagai admin.
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:16px 28px; background:#f7faf8; border-top:1px solid #e5ece7; font-size:12px; color:#8a9a8e;">
                            Email ini dikirim otomatis oleh sistem GrowHub. Jika Anda tidak merasa melakukan permintaan ubah password, segera hubungi Administrator.
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>

