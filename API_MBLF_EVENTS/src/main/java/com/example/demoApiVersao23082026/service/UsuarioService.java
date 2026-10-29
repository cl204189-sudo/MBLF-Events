package com.example.demoApiVersao23082026.service;

import com.example.demoApiVersao23082026.dto.UsuarioDTO;
import com.example.demoApiVersao23082026.exception.BadRequestException;
import com.example.demoApiVersao23082026.exception.NotFoundException;
import com.example.demoApiVersao23082026.model.Perfil;
import com.example.demoApiVersao23082026.model.Usuario;
import com.example.demoApiVersao23082026.repository.PerfilRepository;
import com.example.demoApiVersao23082026.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import com.example.demoApiVersao23082026.dto.AlterarSenhaDTO;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsuarioService {

    @Autowired
    private UsuarioRepository repository;

    @Autowired
    private PerfilRepository perfilRepository;

    @Autowired
    private UsuarioAutenticadoService usuarioAutenticadoService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    public List<UsuarioDTO> listarTodos() {

        return repository.findAll()
                .stream()
                .map(this::converterParaDTO)
                .toList();
    }

    public UsuarioDTO buscar(Integer id) {

        Usuario usuario = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException("Usuário não encontrado"));

        return converterParaDTO(usuario);
    }

    public UsuarioDTO criar(Usuario usuario) {

        if (usuario.getNome() == null ||
                usuario.getNome().isBlank()) {

            throw new BadRequestException(
                    "Nome é obrigatório"
            );
        }

        if (usuario.getEmail() == null ||
                usuario.getEmail().isBlank()) {

            throw new BadRequestException(
                    "Email é obrigatório"
            );
        }

        if (usuario.getSenha() == null ||
                usuario.getSenha().isBlank()) {

            throw new BadRequestException(
                    "Senha é obrigatória"
            );
        }

        if (repository.existsByEmail(usuario.getEmail())) {

            throw new BadRequestException(
                    "Já existe um usuário com esse email"
            );
        }

        Perfil perfilUsuario = perfilRepository
                .findByNome("USUARIO")
                .orElseThrow(() ->
                        new NotFoundException(
                                "Perfil USUARIO não encontrado"
                        ));

        usuario.setPerfil(perfilUsuario);

        usuario.setAtivo(true);

        usuario.setSenha(
                passwordEncoder.encode(
                        usuario.getSenha()
                )
        );

        Usuario salvo = repository.save(usuario);

        return converterParaDTO(salvo);
    }

    public UsuarioDTO buscarMeuPerfil() {

        Usuario usuario =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        return converterParaDTO(usuario);
    }

    public void alterarMinhaSenha(
            AlterarSenhaDTO dto) {

        Usuario usuario =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        if (dto.getSenhaAtual() == null ||
                dto.getSenhaAtual().isBlank()) {

            throw new BadRequestException(
                    "Senha atual é obrigatória"
            );
        }

        if (dto.getNovaSenha() == null ||
                dto.getNovaSenha().isBlank()) {

            throw new BadRequestException(
                    "Nova senha é obrigatória"
            );
        }

        if (!passwordEncoder.matches(
                dto.getSenhaAtual(),
                usuario.getSenha()
        )) {

            throw new BadRequestException(
                    "Senha atual incorreta"
            );
        }

        if (dto.getNovaSenha().length() < 6) {

            throw new BadRequestException(
                    "A nova senha deve possuir pelo menos 6 caracteres"
            );
        }

        usuario.setSenha(
                passwordEncoder.encode(
                        dto.getNovaSenha()
                )
        );

        repository.save(usuario);
    }

    public UsuarioDTO atualizarMeuPerfil(
            Usuario usuario) {

        Usuario existente =
                usuarioAutenticadoService
                        .getUsuarioAutenticado();

        if (usuario.getNome() == null ||
                usuario.getNome().isBlank()) {

            throw new BadRequestException(
                    "Nome é obrigatório"
            );
        }

        if (usuario.getEmail() == null ||
                usuario.getEmail().isBlank()) {

            throw new BadRequestException(
                    "Email é obrigatório"
            );
        }

        existente.setNome(
                usuario.getNome()
        );

        if (!existente.getEmail()
                .equals(usuario.getEmail())
                && repository.existsByEmail(
                usuario.getEmail()
        )) {

            throw new BadRequestException(
                    "Já existe um usuário com esse email"
            );
        }

        existente.setEmail(
                usuario.getEmail()
        );

        existente.setTelefone(
                usuario.getTelefone()
        );

        if (usuario.getSenha() != null &&
                !usuario.getSenha().isBlank()) {

            existente.setSenha(
                    passwordEncoder.encode(
                            usuario.getSenha()
                    )
            );
        }

        Usuario atualizado =
                repository.save(existente);

        return converterParaDTO(
                atualizado
        );
    }

    public UsuarioDTO atualizar(
            Integer id,
            Usuario usuario) {

        Usuario existente = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Usuário não encontrado"
                        ));

        existente.setNome(usuario.getNome());

        if (!existente.getEmail().equals(usuario.getEmail())
                && repository.existsByEmail(usuario.getEmail())) {

            throw new BadRequestException(
                    "Já existe um usuário com esse email"
            );
        }

        existente.setEmail(usuario.getEmail());
        existente.setTelefone(usuario.getTelefone());

        if (usuario.getSenha() != null &&
                !usuario.getSenha().isBlank()) {

            existente.setSenha(
                    passwordEncoder.encode(
                            usuario.getSenha()
                    )
            );
        }

        Usuario atualizado = repository.save(existente);

        return converterParaDTO(atualizado);
    }

    public void deletar(Integer id) {

        Usuario usuario = repository.findById(id)
                .orElseThrow(() ->
                        new NotFoundException(
                                "Usuário não encontrado"
                        ));

        repository.delete(usuario);
    }

    private UsuarioDTO converterParaDTO(
            Usuario usuario) {

        return new UsuarioDTO(
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                usuario.getTelefone(),
                usuario.getPerfil().getNome(),
                usuario.getAtivo(),
                usuario.getDataCadastro()
        );
    }
}