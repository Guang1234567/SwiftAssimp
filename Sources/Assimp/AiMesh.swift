//
//  AiMesh.swift
//
//
//  Created by Christian Treffs on 21.06.19.
//

import CAssimp

public struct AiMesh {
    public struct PrimitiveType: OptionSet {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let point = PrimitiveType(rawValue: aiPrimitiveType_POINT.rawValue)
        public static let line = PrimitiveType(rawValue: aiPrimitiveType_LINE.rawValue)
        public static let triangle = PrimitiveType(rawValue: aiPrimitiveType_TRIANGLE.rawValue)
        public static let polygon = PrimitiveType(rawValue: aiPrimitiveType_POLYGON.rawValue)
    }

    let mesh: aiMesh

    public init(_ aiMesh: aiMesh) {
        mesh = aiMesh
    }

    /// Bitwise combination of the members of the #aiPrimitiveType enum.
    /// This specifies which types of primitives are present in the mesh.
    ///
    /// The "SortByPrimitiveType"-Step can be used to make sure the output meshes consist of one primitive type each.
    public var primitiveTypes: PrimitiveType {
        return PrimitiveType(rawValue: mesh.mPrimitiveTypes)
    }

    /// The number of vertices in this mesh. This is also the size of all of the per-vertex data arrays.
    /// The maximum value for this member is #AI_MAX_VERTICES.
    public var numVertices: Int {
        return Int(mesh.mNumVertices)
    }

    /// The number of primitives (triangles, polygons, lines) in this mesh.
    /// This is also the size of the mFaces array.
    /// The maximum value for this member is #AI_MAX_FACES.
    public var numFaces: Int {
        return Int(mesh.mNumFaces)
    }

    /// Vertex positions. This array is always present in a mesh.
    /// The array is mNumVertices in size.
    public var vertices: [SIMD3<Float>] {
        guard numVertices > 0 else {
            return []
        }
        let vertices = (0..<numVertices)
            .compactMap { mesh.mVertices[$0] }
            .map { $0.vector }

        assert(vertices.count == numVertices)
        return vertices
    }

    /// Vertex normals.
    /// The array contains normalized vectors, NULL if not present.
    /// The array is mNumVertices in size.
    ///
    /// Normals are undefined for point and line primitives.
    /// A mesh consisting of points and lines only may not have normal vectors.
    /// Meshes with mixed primitive types (i.e. lines and triangles) may have normals,
    /// but the normals for vertices that are only referenced by point or line primitives
    /// are undefined and set to QNaN (WARN: qNaN compares to inequal to *everything*, even to qNaN itself.
    public var normals: [SIMD3<Float>] {
        let normals = (0..<numVertices)
            .compactMap { mesh.mNormals[$0] }
            .map { $0.vector }

        assert(normals.count == numVertices)
        return normals
    }

    /// Vertex tangents.
    /// The tangent of a vertex points in the direction of the positive X texture axis.
    /// The array contains normalized vectors, NULL if not present.
    /// The array is mNumVertices in size.
    ///
    /// A mesh consisting of points and lines only may not have normal vectors.
    /// Meshes with mixed primitive types (i.e. lines and triangles) may have normals,
    /// but the normals for vertices that are only referenced by point or line primitives
    /// are undefined and set to qNaN.
    /// See the #mNormals member for a detailed discussion of qNaNs.
    public var tangents: [SIMD3<Float>] {
        guard mesh.mTangents != nil else {
            return []
        }

        let tangents = (0..<numVertices)
            .compactMap { mesh.mTangents[$0] }
            .map { $0.vector }

        assert(tangents.count == numVertices)

        return tangents
    }

    /// Vertex bitangents.
    /// The bitangent of a vertex points in the direction of the positive Y texture axis.
    /// The array contains normalized vectors, NULL if not present.
    /// The array is mNumVertices in size.
    public var bitangents: [SIMD3<Float>] {
        guard mesh.mBitangents != nil else {
            return []
        }

        let bitangents = (0..<numVertices)
            .compactMap { mesh.mBitangents[$0] }
            .map { $0.vector }

        assert(bitangents.count == numVertices)

        return bitangents
    }

    /// Vertex color sets.
    ///
    /// A mesh may contain 0 to #AI_MAX_NUMBER_OF_COLOR_SETS vertex colors per vertex.
    /// NULL if not present.
    /// Each array is mNumVertices in size if present.
    public var colors: [[aiColor4D]] {
        let sets = [UnsafeMutablePointer<aiColor4D>?](withUnsafeBytes(of: mesh.mColors) { ptr in ptr.bindMemory(to: UnsafeMutablePointer<aiColor4D>?.self) })

        let colors: [[aiColor4D]] = sets.compactMap { (optPtr: UnsafeMutablePointer<aiColor4D>?) -> [aiColor4D]? in
            guard let ptr = optPtr else {
                return nil
            }

            let colors = [aiColor4D]((0..<numVertices).compactMap { ptr[$0] })

            return colors
        }
        return colors
    }

    /// Vertex texture coords, also known as UV channels.
    ///
    /// A mesh may contain 0 to AI_MAX_NUMBER_OF_TEXTURECOORDS per vertex.
    /// NULL if not present.
    /// The array is mNumVertices in size.
    public var textureCoords: [[SIMD3<Float>]] {
        let channels = [UnsafeMutablePointer<aiVector3D>?](withUnsafeBytes(of: mesh.mTextureCoords) { ptr in ptr.bindMemory(to: UnsafeMutablePointer<aiVector3D>?.self) })

        let coords: [[SIMD3<Float>]] = channels.compactMap { (optPtr: UnsafeMutablePointer<aiVector3D>?) -> [SIMD3<Float>]? in
            guard let ptr = optPtr else {
                return nil
            }

            let texCoors = (0..<numVertices)
                .compactMap { ptr[$0] }
                .map { $0.vector }

            return texCoors
        }

        return coords
    }

    /// Specifies the number of components for a given UV channel.
    /// Up to three channels are supported (UVW, for accessing volume or cube maps).
    ///
    /// If the value is 2 for a given channel n, the component p.z of mTextureCoords[n][p] is set to 0.0f.
    /// If the value is 1 for a given channel, p.y is set to 0.0f, too.
    /// 4D coords are not supported
    public var numUVComponents: [Int] {
        return [UInt32](withUnsafeBytes(of: mesh.mNumUVComponents) { ptr in ptr.bindMemory(to: UInt32.self) }).map { Int($0) }.filter { $0 > 0 }
    }

    /// The faces the mesh is constructed from.
    /// Each face refers to a number of vertices by their indices.
    /// This array is always present in a mesh, its size is given in mNumFaces.
    ///
    /// If the #AI_SCENE_FLAGS_NON_VERBOSE_FORMAT is NOT set each face references an unique set of vertices.
    public var faces: [AiFace] {
        guard numFaces > 0 else {
            return []
        }

        let faces = (0..<numFaces)
            .compactMap { mesh.mFaces[$0] }
            .map { AiFace($0) }

        assert(faces.count == numFaces)

        return faces
    }

    /// The number of bones this mesh contains.
    /// Can be 0, in which case the mBones array is NULL.
    public var numBones: Int {
        return Int(mesh.mNumBones)
    }

    /// The material used by this mesh.
    ///
    /// A mesh uses only a single material.
    /// If an imported model uses multiple materials, the import splits up the mesh.
    /// Use this value as index into the scene's material list.
    public var materialIndex: Int {
        return Int(mesh.mMaterialIndex)
    }

    /// Name of the mesh. Meshes can be named, but this is not a requirement and leaving this field empty is totally fine.
    ///
    /// There are mainly three uses for mesh names:
    ///    - some formats name nodes and meshes independently.
    ///    - importers tend to split meshes up to meet the one-material-per-mesh requirement.
    ///      Assigning the same (dummy) name to each of the result meshes aids the caller at recovering the original mesh partitioning.
    ///    - Vertex animations refer to meshes by their names.
    ///
    public var name: String {
        return String(aiString: mesh.mName) ?? ""
    }

    /// The number of attachment meshes.
    ///
    /// **Note:** Currently only works with Collada loader.
    public var numAnimMeshes: Int {
        return Int(mesh.mNumAnimMeshes)
    }

    /// Method of morphing when animeshes are specified.
    public var method: UInt32 {
        return mesh.mMethod
    }
}

// MARK: - Equatable
extension AiMesh: Equatable {
    public static func == (lhs: AiMesh, rhs: AiMesh) -> Bool {
        return lhs.name == rhs.name &&
            lhs.materialIndex == rhs.materialIndex &&
            lhs.bitangents == rhs.bitangents &&
            lhs.faces == rhs.faces &&
            lhs.method == rhs.method &&
            lhs.normals == rhs.normals &&
            lhs.numAnimMeshes == rhs.numAnimMeshes &&
            lhs.numBones == rhs.numBones &&
            lhs.numFaces == rhs.numFaces &&
            lhs.numUVComponents == rhs.numUVComponents &&
            lhs.numVertices == rhs.numVertices &&
            lhs.primitiveTypes == rhs.primitiveTypes &&
            lhs.tangents == rhs.tangents &&
            lhs.textureCoords == rhs.textureCoords &&
            lhs.vertices == rhs.vertices

        //FIXME: lhs.colors == rhs.colors &&

    }
}

// MARK: - Hashable
extension AiMesh: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(materialIndex)
        hasher.combine(bitangents)
        hasher.combine(faces)
        hasher.combine(method)
        hasher.combine(normals)
        hasher.combine(numAnimMeshes)
        hasher.combine(numBones)
        hasher.combine(numFaces)
        hasher.combine(numUVComponents)
        hasher.combine(numVertices)
        hasher.combine(primitiveTypes.rawValue)
        hasher.combine(tangents)
        hasher.combine(textureCoords)
        hasher.combine(vertices)
        // FIXME: hasher.combine(colors)
    }
}
