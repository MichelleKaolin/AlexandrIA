@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    @Autowired
    private UsuarioRepository repository;

    @PostMapping("/cadastro")
    public ResponseEntity<?> cadastrar(@RequestBody Usuario user) {
        user.setSenha(new BCryptPasswordEncoder().encode(user.getSenha()));
        return ResponseEntity.ok(repository.save(user));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        return ResponseEntity.ok("Sessão Iniciada");
    }
}