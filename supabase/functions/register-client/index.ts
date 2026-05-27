import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Gera senha aleatória forte de 10 caracteres usando crypto seguro
function generatePassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#!'
  const array = new Uint8Array(10)
  crypto.getRandomValues(array)
  return Array.from(array).map(b => chars[b % chars.length]).join('')
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { name, email, phone, resendApiKey, resendFrom } = await req.json()

    // Validação
    if (!name || !email || !phone) {
      return new Response(
        JSON.stringify({ error: 'Campos obrigatórios: nome, email e WhatsApp.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Client Admin com service_role key (disponível automaticamente em Edge Functions)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    // Verifica se já existe um cliente com o mesmo telefone na tabela studio_customers
    const { data: existingCustomer, error: checkError } = await supabaseAdmin
      .from('studio_customers')
      .select('id')
      .eq('phone', phone)
      .limit(1)

    if (existingCustomer && existingCustomer.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Este número de WhatsApp já está cadastrado em outra conta.' }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Gera senha aleatória segura
    const password = generatePassword()

    // Cria o usuário no Supabase Auth (confirmado por padrão)
    const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Cadastro imediato sem travas de e-mail
      user_metadata: {
        full_name: name,
        phone,
        is_temporary_password: true
      }
    })

    if (createError) {
      const alreadyExists =
        createError.message.toLowerCase().includes('already been registered') ||
        createError.message.toLowerCase().includes('already registered') ||
        createError.message.toLowerCase().includes('user already exists')

      if (alreadyExists) {
        return new Response(
          JSON.stringify({ error: 'Este e-mail já possui um cadastro. Tente fazer login.' }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      return new Response(
        JSON.stringify({ error: createError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Insere o cliente na tabela public.studio_customers do banco de dados
    if (userData?.user) {
      const { error: customerError } = await supabaseAdmin
        .from('studio_customers')
        .insert([{
          tenant_id: 'bfbe574d-34f5-7080-1bce-0b9200bc42bf',
          name: name,
          email: email,
          phone: phone
        }])
      if (customerError) {
        console.error('Erro ao registrar em public.customers:', customerError.message)
      }
    }

    const confirmLink = null

    // ── Envia e-mail via Resend ────────────────────────────────────
    const resendKey = resendApiKey || Deno.env.get('RESEND_API_KEY')
    const fromEmail = resendFrom || Deno.env.get('RESEND_FROM') || 'Studio Mireille Marques <onboarding@resend.dev>'

    if (resendKey) {
      const emailHtml = `
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#111;font-family:Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;background:#1a1a1a;border-radius:12px;overflow:hidden;">
    
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#d4af37,#f5d76e);padding:28px 24px;text-align:center;">
      <div style="font-size:28px;margin-bottom:8px;">🌸</div>
      <h1 style="margin:0;color:#1a1a1a;font-size:20px;font-weight:700;letter-spacing:0.5px;">
        Stúdio Mireille Marques
      </h1>
      <p style="margin:6px 0 0;color:#5a4000;font-size:13px;">Sua conta está pronta!</p>
    </div>

    <!-- Body -->
    <div style="padding:28px 24px;">
      <p style="color:#e0e0e0;font-size:15px;margin:0 0 8px;">Olá, <strong style="color:#d4af37;">${name}</strong>! 👋</p>
      <p style="color:#b0b0b0;font-size:13px;margin:0 0 24px;line-height:1.6;">
        Seu cadastro no Stúdio Mireille Marques foi realizado com sucesso. 
        Abaixo estão seus dados de acesso:
      </p>

      <!-- Credenciais -->
      <div style="background:#242424;border:1px solid #d4af37;border-radius:10px;padding:20px;margin-bottom:20px;text-align:center;">
        <p style="margin:0 0 4px;color:#808080;font-size:10px;text-transform:uppercase;letter-spacing:1.5px;">E-mail de Acesso</p>
        <p style="margin:0 0 16px;color:#e0e0e0;font-size:15px;font-weight:600;">${email}</p>
        <hr style="border:none;border-top:1px solid #333;margin:0 0 16px;" />
        <p style="margin:0 0 4px;color:#808080;font-size:10px;text-transform:uppercase;letter-spacing:1.5px;">Sua Senha de Acesso</p>
        <p style="margin:0;color:#d4af37;font-size:26px;font-weight:700;letter-spacing:4px;font-family:monospace;">${password}</p>
      </div>

      <p style="color:#b0b0b0;font-size:12px;line-height:1.6;margin:0 0 24px;">
        ⚠️ <strong>Importante:</strong> Guarde sua senha em local seguro. 
        Você poderá alterá-la a qualquer momento após fazer login.
      </p>

      ${confirmLink ? `
      <!-- Botão de Confirmação -->
      <div style="text-align:center;margin-bottom:24px;">
        <a href="${confirmLink}" 
           style="display:inline-block;background:linear-gradient(135deg,#d4af37,#f5d76e);
                  color:#1a1a1a;text-decoration:none;padding:14px 32px;
                  border-radius:8px;font-weight:700;font-size:14px;">
          ✅ Confirmar Minha Conta
        </a>
        <p style="color:#808080;font-size:11px;margin:10px 0 0;">
          Clique para ativar sua conta. Após confirmar, faça login com sua senha.
        </p>
      </div>
      ` : ''}

    </div>

    <!-- Footer -->
    <div style="background:#111;padding:16px 24px;text-align:center;border-top:1px solid #222;">
      <p style="margin:0;color:#444;font-size:11px;">
        Powered by <strong style="color:#d4af37;">CConecta</strong> • Sistema para Salões de Beleza
      </p>
    </div>
  </div>
</body>
</html>`

      const resendRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: fromEmail,
          to: email,
          subject: '🌸 Bem-vinda! Seus dados de acesso ao Stúdio Mireille Marques',
          html: emailHtml,
        })
      })

      if (!resendRes.ok) {
        const resendError = await resendRes.text()
        console.error('Erro Resend:', resendError)
      }
    } else {
      console.warn('RESEND_API_KEY não configurada no corpo da requisição ou nas secrets. E-mail não enviado.')
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Cadastro realizado!`,
        emailSent: !!resendKey,
        password: password // Devolve a senha para exibição na tela
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Erro desconhecido'
    return new Response(
      JSON.stringify({ error: 'Erro interno: ' + message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
