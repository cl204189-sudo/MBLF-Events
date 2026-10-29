package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.exception.NotFoundException;
import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class UsuarioAutenticadoService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    public Usuario getUsuarioAutenticado() {

        Authentication authentication =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        String email =
                authentication.getName();

        return usuarioRepository
                .findByEmail(email)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Usuário autenticado não encontrado"
                        ));
    }

    public Integer getUsuarioId() {
        return getUsuarioAutenticado().getId();
    }
}