@Service
public class DocumentoService {
    @Autowired
    private DocumentoRepository repository;

    public Documento salvarDocumento(Documento doc) {
        return repository.save(doc);
    }

    public List<Documento> listarTodos() {
        return repository.findAll();
    }
}