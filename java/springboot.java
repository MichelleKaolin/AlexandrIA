@RestController
@RequestMapping("/api/biblioteca")
public class BibliotecaController {

    @Autowired
    private FavoritoRepository favoritoRepository;

    @GetMapping("/{usuarioId}")
    public ResponseEntity<List<Material>> getFavoritos(@PathVariable Long usuarioId) {
        return ResponseEntity.ok(favoritoRepository.findMateriaisByUsuarioId(usuarioId));
    }

    @PostMapping("/favoritar")
    public ResponseEntity<?> favoritar(@RequestBody FavoritoDTO dto) {
        Favorito fav = new Favorito(dto.getUsuarioId(), dto.getMaterialId());
        favoritoRepository.save(fav);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/remover/{id}")
    public ResponseEntity<?> remover(@PathVariable Long id) {
        favoritoRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
    @Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**").allowedOrigins("*").allowedMethods("GET", "POST", "PUT", "DELETE");
    }
}
}