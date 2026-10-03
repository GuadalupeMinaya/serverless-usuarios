package com.utesa.usuariosapi.infrastructure.adapter.in.rest;

import com.utesa.usuariosapi.application.port.in.UsuarioServicePort;
import com.utesa.usuariosapi.domain.Usuario;
import com.utesa.usuariosapi.infrastructure.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final UsuarioServicePort usuarioServicePort;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public AuthController(UsuarioServicePort usuarioServicePort,
                          AuthenticationManager authenticationManager,
                          JwtService jwtService,
                          PasswordEncoder passwordEncoder) {
        this.usuarioServicePort = usuarioServicePort;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@RequestBody Usuario usuario) {
        usuario.setPassword(passwordEncoder.encode(usuario.getPassword()));
        usuarioServicePort.crear(usuario);
        String token = jwtService.generarToken(usuario.getEmail());
        return new AuthResponse(token);
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest loginRequest) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword())
        );
        String token = jwtService.generarToken(loginRequest.getEmail());
        return new AuthResponse(token);
    }
}