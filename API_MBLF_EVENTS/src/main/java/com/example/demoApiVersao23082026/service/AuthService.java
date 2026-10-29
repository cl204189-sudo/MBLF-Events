package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.dto.LoginDTO;
import com.example.demoApiVersao23082026.dto.LoginResponseDTO;
import com.example.demoApiVersao23082026.exception.BadRequestException;
import com.example.demoApiVersao23082026.exception.NotFoundException;
import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    public LoginResponseDTO login(LoginDTO dto) {

        if (dto.getEmail() == null ||
                dto.getEmail().isBlank()) {

            throw new BadRequestException(
                    "Email é obrigatório"
            );
        }

        if (dto.getSenha() == null ||
                dto.getSenha().isBlank()) {

            throw new BadRequestException(
                    "Senha é obrigatória"
            );
        }

        Usuario usuario = usuarioRepository
                .findByEmail(dto.getEmail())
                .orElseThrow(() ->
                        new NotFoundException(
                                "Usuário não encontrado"
                        ));

        if (usuario.getAtivo() == null ||
                !usuario.getAtivo()) {

            throw new BadRequestException(
                    "Usuário está desativado"
            );
        }

        boolean senhaCorreta =
                passwordEncoder.matches(
                        dto.getSenha(),
                        usuario.getSenha()
                );

        if (!senhaCorreta) {
            throw new BadRequestException(
                    "Senha inválida"
            );
        }

        String token =
                jwtService.gerarToken(usuario);

        return new LoginResponseDTO(
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                usuario.getPerfil().getNome(),
                token
        );
    }
}