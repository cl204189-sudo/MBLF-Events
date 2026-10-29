package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailsService
        implements UserDetailsService {

    @Autowired
    private UsuarioRepository repository;

    @Override
    public UserDetails loadUserByUsername(
            String email)
            throws UsernameNotFoundException {

        Usuario usuario = repository
                .findByEmail(email)
                .orElseThrow(() ->
                        new UsernameNotFoundException(
                                "Usuário não encontrado"
                        ));

        return User.builder()
                .username(usuario.getEmail())
                .password(usuario.getSenha())

                .authorities(
                        "ROLE_" +
                                usuario.getPerfil()
                                        .getNome()
                )

                .disabled(
                        !Boolean.TRUE.equals(
                                usuario.getAtivo()
                        )
                )

                .build();
    }
}