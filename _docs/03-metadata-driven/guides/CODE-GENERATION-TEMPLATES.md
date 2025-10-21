# 코드 생성 템플릿 및 예제

> 메타데이터 기반 코드 자동 생성 시스템의 템플릿 모음

## 목차

1. [Generator 기본 구조](#generator-기본-구조)
2. [Database DDL Generator](#database-ddl-generator)
3. [GraphQL Schema Generator](#graphql-schema-generator)
4. [TypeScript Types Generator](#typescript-types-generator)
5. [Resolver Generator](#resolver-generator)
6. [React Form Generator](#react-form-generator)
7. [React Table Generator](#react-table-generator)
8. [Migration Generator](#migration-generator)

---

## Generator 기본 구조

### Base Generator 클래스

```typescript
// generators/base-generator.ts

import prettier from 'prettier';
import { MetadataService } from '../services/metadata-service';
import type { TableMetadata } from '../types/metadata';

export abstract class BaseGenerator {
  protected metadata: MetadataService;

  constructor(metadata: MetadataService) {
    this.metadata = metadata;
  }

  /**
   * 코드 생성 메인 메서드
   */
  abstract generate(tables: TableMetadata[]): Promise<string | void>;

  /**
   * 코드 포맷팅
   */
  protected async formatCode(code: string, parser: 'typescript' | 'graphql' | 'sql'): Promise<string> {
    try {
      return await prettier.format(code, {
        parser,
        semi: true,
        singleQuote: true,
        trailingComma: 'es5',
        printWidth: 100,
        tabWidth: 2,
      });
    } catch (error) {
      console.error('Format error:', error);
      return code;
    }
  }

  /**
   * 파일 헤더 생성
   */
  protected generateFileHeader(description: string): string {
    const timestamp = new Date().toISOString();
    return `
/**
 * ${description}
 *
 * 자동 생성된 파일입니다. 직접 수정하지 마세요.
 * Generated at: ${timestamp}
 *
 * @warning DO NOT EDIT - This file is auto-generated
 */
    `.trim();
  }

  /**
   * 문자열 변환 유틸리티
   */
  protected toPascalCase(str: string): string {
    return str
      .split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join('');
  }

  protected toCamelCase(str: string): string {
    const pascal = this.toPascalCase(str);
    return pascal.charAt(0).toLowerCase() + pascal.slice(1);
  }

  protected toSnakeCase(str: string): string {
    return str
      .replace(/([A-Z])/g, '_$1')
      .toLowerCase()
      .replace(/^_/, '');
  }

  /**
   * SQL 값 이스케이프
   */
  protected escapeSqlValue(value: any, type: string): string {
    if (value === null || value === undefined) return 'NULL';

    if (type.includes('CHAR') || type.includes('TEXT') || type === 'DATE' || type === 'TIMESTAMP') {
      return `'${String(value).replace(/'/g, "''")}'`;
    }

    if (type === 'BOOLEAN') {
      return value ? 'TRUE' : 'FALSE';
    }

    return String(value);
  }

  /**
   * GraphQL 타입 변환
   */
  protected pgTypeToGraphQLType(pgType: string): string {
    const typeMap: Record<string, string> = {
      'BIGSERIAL': 'ID',
      'SERIAL': 'ID',
      'INTEGER': 'Int',
      'BIGINT': 'Int',
      'SMALLINT': 'Int',
      'DECIMAL': 'Float',
      'NUMERIC': 'Float',
      'REAL': 'Float',
      'DOUBLE PRECISION': 'Float',
      'BOOLEAN': 'Boolean',
      'VARCHAR': 'String',
      'TEXT': 'String',
      'CHAR': 'String',
      'DATE': 'DateTime',
      'TIMESTAMP': 'DateTime',
      'TIMESTAMPTZ': 'DateTime',
      'JSON': 'JSON',
      'JSONB': 'JSON',
    };

    const baseType = pgType.split('(')[0].toUpperCase();
    return typeMap[baseType] || 'String';
  }

  /**
   * TypeScript 타입 변환
   */
  protected pgTypeToTsType(pgType: string): string {
    const typeMap: Record<string, string> = {
      'BIGSERIAL': 'string',
      'SERIAL': 'number',
      'INTEGER': 'number',
      'BIGINT': 'string',
      'SMALLINT': 'number',
      'DECIMAL': 'number',
      'NUMERIC': 'number',
      'REAL': 'number',
      'DOUBLE PRECISION': 'number',
      'BOOLEAN': 'boolean',
      'VARCHAR': 'string',
      'TEXT': 'string',
      'CHAR': 'string',
      'DATE': 'Date',
      'TIMESTAMP': 'Date',
      'TIMESTAMPTZ': 'Date',
      'JSON': 'any',
      'JSONB': 'any',
    };

    const baseType = pgType.split('(')[0].toUpperCase();
    return typeMap[baseType] || 'string';
  }
}
```

---

## Database DDL Generator

```typescript
// generators/database-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata, ColumnMetadata } from '../types/metadata';
import fs from 'fs/promises';

export class DatabaseGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    const header = this.generateFileHeader('Database DDL Schema');
    const ddl = await this.generateDDL(tables);

    return this.formatCode(`${header}\n\n${ddl}`, 'sql');
  }

  private async generateDDL(tables: TableMetadata[]): string {
    const parts: string[] = [];

    // 1. Extensions
    parts.push(this.generateExtensions());

    // 2. Enums
    parts.push(this.generateEnums(tables));

    // 3. Tables
    for (const table of tables) {
      parts.push(this.generateTableDDL(table));
      parts.push(this.generateIndexes(table));
    }

    // 4. Foreign Keys (관계)
    const relations = await this.metadata.getAllRelations();
    parts.push(this.generateForeignKeys(relations));

    // 5. Functions & Triggers
    parts.push(this.generateTriggers());

    return parts.filter(Boolean).join('\n\n');
  }

  private generateExtensions(): string {
    return `
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For full-text search
    `.trim();
  }

  private generateEnums(tables: TableMetadata[]): string {
    const enums = new Set<string>();
    const enumDefs: string[] = [];

    for (const table of tables) {
      for (const column of table.columns) {
        if (column.enumOptions && column.graphqlType) {
          const enumName = `${column.graphqlType.toLowerCase()}_enum`;

          if (!enums.has(enumName)) {
            enums.add(enumName);

            const values = column.enumOptions
              .map((opt: any) => `'${opt.value}'`)
              .join(', ');

            enumDefs.push(`
CREATE TYPE ${enumName} AS ENUM (${values});
            `.trim());
          }
        }
      }
    }

    return enumDefs.length > 0
      ? `-- Enums\n${enumDefs.join('\n\n')}`
      : '';
  }

  private generateTableDDL(table: TableMetadata): string {
    const columns = table.columns
      .map(col => this.generateColumnDDL(col))
      .join(',\n    ');

    const constraints = this.generateTableConstraints(table);

    return `
-- Table: ${table.tableName}
CREATE TABLE ${table.schemaName}.${table.tableName} (
    ${columns}${constraints ? ',\n\n    ' + constraints : ''}
);

COMMENT ON TABLE ${table.schemaName}.${table.tableName} IS '${table.label}';
${this.generateColumnComments(table)}
    `.trim();
  }

  private generateColumnDDL(column: ColumnMetadata): string {
    let ddl = `${column.pgColumn} ${column.pgType}`;

    // Primary Key
    if (column.isPrimaryKey) {
      ddl += ' PRIMARY KEY';
    }

    // NOT NULL
    if (column.isRequired && !column.isPrimaryKey) {
      ddl += ' NOT NULL';
    }

    // DEFAULT
    if (column.defaultValue && !column.isPrimaryKey) {
      ddl += ` DEFAULT ${this.escapeSqlValue(column.defaultValue, column.pgType)}`;
    }

    // UNIQUE
    if (column.isUnique && !column.isPrimaryKey) {
      ddl += ' UNIQUE';
    }

    return ddl;
  }

  private generateTableConstraints(table: TableMetadata): string {
    const constraints: string[] = [];

    // CHECK constraints for enums
    for (const column of table.columns) {
      if (column.enumOptions && !column.pgType.includes('enum')) {
        const values = column.enumOptions
          .map((opt: any) => `'${opt.value}'`)
          .join(', ');

        constraints.push(
          `CONSTRAINT check_${table.tableName}_${column.pgColumn} ` +
          `CHECK (${column.pgColumn} IN (${values}))`
        );
      }
    }

    return constraints.join(',\n    ');
  }

  private generateColumnComments(table: TableMetadata): string {
    return table.columns
      .filter(col => col.comment || col.label)
      .map(col => {
        const comment = col.comment || col.label;
        return `COMMENT ON COLUMN ${table.schemaName}.${table.tableName}.${col.pgColumn} IS '${comment}';`;
      })
      .join('\n');
  }

  private generateIndexes(table: TableMetadata): string {
    const indexes: string[] = [];

    for (const column of table.columns) {
      if (column.isIndexed && !column.isPrimaryKey) {
        const indexName = `idx_${table.tableName}_${column.pgColumn}`;
        const indexType = column.indexConfig?.type || 'BTREE';

        let indexDef = `CREATE INDEX ${indexName} ON ${table.tableName} `;

        if (indexType !== 'BTREE') {
          indexDef += `USING ${indexType} `;
        }

        indexDef += `(${column.pgColumn})`;

        // Partial index for searchable fields
        if (column.isSearchable) {
          indexDef += ` WHERE ${column.pgColumn} IS NOT NULL`;
        }

        indexDef += ';';
        indexes.push(indexDef);
      }

      // GIN index for JSONB columns
      if (column.pgType === 'JSONB') {
        const indexName = `idx_${table.tableName}_${column.pgColumn}_gin`;
        indexes.push(
          `CREATE INDEX ${indexName} ON ${table.tableName} USING GIN (${column.pgColumn});`
        );
      }

      // Full-text search index
      if (column.isSearchable && column.pgType.includes('TEXT')) {
        const indexName = `idx_${table.tableName}_${column.pgColumn}_fts`;
        indexes.push(
          `CREATE INDEX ${indexName} ON ${table.tableName} USING GIN (to_tsvector('simple', ${column.pgColumn}));`
        );
      }
    }

    return indexes.length > 0
      ? `-- Indexes for ${table.tableName}\n${indexes.join('\n')}`
      : '';
  }

  private generateForeignKeys(relations: any[]): string {
    const fks = relations.map(rel => {
      const constraintName = rel.constraintName ||
        `fk_${rel.fromTable}_${rel.fromColumn}`;

      return `
ALTER TABLE ${rel.fromSchema}.${rel.fromTable}
ADD CONSTRAINT ${constraintName}
FOREIGN KEY (${rel.fromColumn})
REFERENCES ${rel.toSchema}.${rel.toTable} (${rel.toColumn})
${rel.isCascadeDelete ? 'ON DELETE CASCADE' : 'ON DELETE RESTRICT'};
      `.trim();
    }).join('\n\n');

    return fks ? `-- Foreign Keys\n${fks}` : '';
  }

  private generateTriggers(): string {
    return `
-- Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
-- (이 부분은 각 테이블별로 동적으로 생성됨)
    `.trim();
  }
}
```

---

## GraphQL Schema Generator

```typescript
// generators/graphql-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata } from '../types/metadata';

export class GraphQLGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    const header = this.generateFileHeader('GraphQL Schema');
    const schema = this.generateSchema(tables);

    return this.formatCode(`${header}\n\n${schema}`, 'graphql');
  }

  private generateSchema(tables: TableMetadata[]): string {
    const parts: string[] = [];

    // 1. Scalars
    parts.push(this.generateScalars());

    // 2. Enums
    parts.push(this.generateEnums(tables));

    // 3. Types
    for (const table of tables) {
      parts.push(this.generateType(table));
      parts.push(this.generateInputType(table));
      parts.push(this.generateFilterType(table));
    }

    // 4. Common types
    parts.push(this.generateCommonTypes());

    // 5. Query
    parts.push(this.generateQuery(tables));

    // 6. Mutation
    parts.push(this.generateMutation(tables));

    return parts.filter(Boolean).join('\n\n');
  }

  private generateScalars(): string {
    return `
# Scalar types
scalar DateTime
scalar JSON
    `.trim();
  }

  private generateEnums(tables: TableMetadata[]): string {
    const enums = new Map<string, Set<string>>();

    for (const table of tables) {
      for (const column of table.columns) {
        if (column.enumOptions && column.graphqlType) {
          const enumName = column.graphqlType;

          if (!enums.has(enumName)) {
            enums.set(enumName, new Set());
          }

          const values = enums.get(enumName)!;
          column.enumOptions.forEach((opt: any) => values.add(opt.value));
        }
      }
    }

    const enumDefs = Array.from(enums.entries()).map(([name, values]) => {
      const valueList = Array.from(values).join('\n  ');
      return `enum ${name} {\n  ${valueList}\n}`;
    });

    return enumDefs.length > 0
      ? `# Enums\n${enumDefs.join('\n\n')}`
      : '';
  }

  private generateType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .filter(col => col.isGraphqlOutput)
      .map(col => {
        const nullable = col.isRequired ? '!' : '';
        return `  ${col.graphqlField}: ${col.graphqlType}${nullable}`;
      })
      .join('\n');

    // 관계 필드 추가
    const relations = table.relations || [];
    const relationFields = relations
      .map(rel => {
        const targetType = this.toPascalCase(rel.toTable);
        const isArray = rel.relationType.includes('Many');
        return `  ${rel.graphqlField}: ${isArray ? `[${targetType}!]!` : targetType}`;
      })
      .join('\n');

    return `
type ${typeName} {
${fields}
${relationFields ? '\n  # Relations\n' + relationFields : ''}
}
    `.trim();
  }

  private generateInputType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .filter(col => col.isGraphqlInput && !col.isPrimaryKey)
      .map(col => {
        const nullable = col.isRequired ? '!' : '';
        return `  ${col.graphqlField}: ${col.graphqlType}${nullable}`;
      })
      .join('\n');

    return `
input ${typeName}Input {
${fields}
}

input ${typeName}UpdateInput {
${fields.replace(/!/g, '')}
}
    `.trim();
  }

  private generateFilterType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .filter(col => col.isFilterable)
      .map(col => `  ${col.graphqlField}: ${col.graphqlType}`)
      .join('\n');

    return `
input ${typeName}Filter {
${fields}
  search: String
  createdAfter: DateTime
  createdBefore: DateTime
}
    `.trim();
  }

  private generateCommonTypes(): string {
    return `
# Common types
type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

input SortInput {
  field: String!
  direction: SortDirection!
}

enum SortDirection {
  ASC
  DESC
}
    `.trim();
  }

  private generateQuery(tables: TableMetadata[]): string {
    const queries = tables
      .filter(table => table.isApiEnabled)
      .map(table => {
        const typeName = this.toPascalCase(table.tableName);
        const fieldName = this.toCamelCase(table.tableName);
        const fieldNamePlural = `${fieldName}s`;

        return `
  # ${table.label}
  ${fieldName}(id: ID!): ${typeName}
  ${fieldNamePlural}(
    filter: ${typeName}Filter
    sort: SortInput
    limit: Int = 20
    offset: Int = 0
  ): [${typeName}!]!
  ${fieldNamePlural}Count(filter: ${typeName}Filter): Int!
        `.trim();
      })
      .join('\n\n');

    return `
type Query {
${queries}
}
    `.trim();
  }

  private generateMutation(tables: TableMetadata[]): string {
    const mutations = tables
      .filter(table => table.isApiEnabled)
      .map(table => {
        const typeName = this.toPascalCase(table.tableName);
        const fieldName = this.toCamelCase(table.tableName);

        return `
  # ${table.label}
  create${typeName}(input: ${typeName}Input!): ${typeName}!
  update${typeName}(id: ID!, input: ${typeName}UpdateInput!): ${typeName}!
  delete${typeName}(id: ID!): Boolean!
        `.trim();
      })
      .join('\n\n');

    return `
type Mutation {
${mutations}
}
    `.trim();
  }
}
```

---

## TypeScript Types Generator

```typescript
// generators/typescript-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata } from '../types/metadata';

export class TypeScriptGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    const header = this.generateFileHeader('TypeScript Type Definitions');
    const types = this.generateTypes(tables);

    return this.formatCode(`${header}\n\n${types}`, 'typescript');
  }

  private generateTypes(tables: TableMetadata[]): string {
    const parts: string[] = [];

    // 1. Enums
    parts.push(this.generateEnums(tables));

    // 2. Entity types
    for (const table of tables) {
      parts.push(this.generateEntityType(table));
      parts.push(this.generateInputType(table));
      parts.push(this.generateFilterType(table));
    }

    // 3. Common types
    parts.push(this.generateCommonTypes());

    return parts.filter(Boolean).join('\n\n');
  }

  private generateEnums(tables: TableMetadata[]): string {
    const enums = new Map<string, Set<string>>();

    for (const table of tables) {
      for (const column of table.columns) {
        if (column.enumOptions && column.graphqlType) {
          const enumName = column.graphqlType;

          if (!enums.has(enumName)) {
            enums.set(enumName, new Set());
          }

          const values = enums.get(enumName)!;
          column.enumOptions.forEach((opt: any) => values.add(opt.value));
        }
      }
    }

    const enumDefs = Array.from(enums.entries()).map(([name, values]) => {
      const entries = Array.from(values)
        .map(v => `  ${v} = '${v}'`)
        .join(',\n');

      return `export enum ${name} {\n${entries}\n}`;
    });

    return enumDefs.length > 0
      ? `// Enums\n${enumDefs.join('\n\n')}`
      : '';
  }

  private generateEntityType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .map(col => {
        const tsType = this.getTsType(col);
        const nullable = col.isRequired ? '' : ' | null';
        return `  ${col.graphqlField}: ${tsType}${nullable};`;
      })
      .join('\n');

    // Relations
    const relations = table.relations || [];
    const relationFields = relations
      .map(rel => {
        const targetType = this.toPascalCase(rel.toTable);
        const isArray = rel.relationType.includes('Many');
        return `  ${rel.graphqlField}?: ${isArray ? `${targetType}[]` : targetType};`;
      })
      .join('\n');

    return `
/**
 * ${table.label}
 * ${table.description || ''}
 */
export interface ${typeName} {
${fields}
${relationFields ? '\n  // Relations\n' + relationFields : ''}
}
    `.trim();
  }

  private generateInputType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .filter(col => col.isGraphqlInput && !col.isPrimaryKey)
      .map(col => {
        const tsType = this.getTsType(col);
        const nullable = col.isRequired ? '' : '?';
        return `  ${col.graphqlField}${nullable}: ${tsType};`;
      })
      .join('\n');

    return `
export interface ${typeName}Input {
${fields}
}

export interface ${typeName}UpdateInput {
${fields.replace(/;/g, ' | undefined;')}
}
    `.trim();
  }

  private generateFilterType(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);

    const fields = table.columns
      .filter(col => col.isFilterable)
      .map(col => {
        const tsType = this.getTsType(col);
        return `  ${col.graphqlField}?: ${tsType};`;
      })
      .join('\n');

    return `
export interface ${typeName}Filter {
${fields}
  search?: string;
  createdAfter?: Date;
  createdBefore?: Date;
}
    `.trim();
  }

  private getTsType(column: any): string {
    if (column.enumOptions) {
      return column.graphqlType;
    }

    return this.pgTypeToTsType(column.pgType);
  }

  private generateCommonTypes(): string {
    return `
// Common types
export interface PageInfo {
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  startCursor?: string;
  endCursor?: string;
}

export interface PaginationInput {
  limit?: number;
  offset?: number;
  cursor?: string;
}

export interface SortInput {
  field: string;
  direction: 'ASC' | 'DESC';
}

export interface Connection<T> {
  edges: Edge<T>[];
  pageInfo: PageInfo;
  totalCount: number;
}

export interface Edge<T> {
  node: T;
  cursor: string;
}
    `.trim();
  }
}
```

이어서 나머지 Generator들(Resolver, React Form, React Table, Migration)의 템플릿을 작성하겠습니다.

---

## Resolver Generator

```typescript
// generators/resolver-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata } from '../types/metadata';

export class ResolverGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    const header = this.generateFileHeader('GraphQL Resolvers');
    const resolvers = this.generateResolvers(tables);

    return this.formatCode(`${header}\n\n${resolvers}`, 'typescript');
  }

  private generateResolvers(tables: TableMetadata[]): string {
    const imports = this.generateImports(tables);
    const resolverDefs = tables
      .filter(t => t.isApiEnabled)
      .map(t => this.generateTableResolvers(t))
      .join('\n\n');

    const mergedResolvers = this.generateMergedResolvers(tables);

    return `
${imports}

${resolverDefs}

${mergedResolvers}
    `.trim();
  }

  private generateImports(tables: TableMetadata[]): string {
    return `
import type { Resolvers } from '../types/graphql';
import type { GraphQLContext } from '../types/context';
${tables.map(t => {
  const typeName = this.toPascalCase(t.tableName);
  return `import type { ${typeName}, ${typeName}Input, ${typeName}UpdateInput, ${typeName}Filter } from '../types';`;
}).join('\n')}
    `.trim();
  }

  private generateTableResolvers(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);
    const serviceName = this.toCamelCase(table.tableName);

    return `
/**
 * ${table.label} Resolvers
 */
export const ${serviceName}Resolvers: Resolvers = {
  Query: {
    // Get single ${table.label}
    async ${serviceName}(parent, { id }, context: GraphQLContext) {
      return await context.services.${serviceName}.findById(id);
    },

    // Get multiple ${table.label}s
    async ${serviceName}s(parent, { filter, sort, limit = 20, offset = 0 }, context: GraphQLContext) {
      return await context.services.${serviceName}.findAll({
        filter,
        sort,
        pagination: { limit, offset }
      });
    },

    // Count ${table.label}s
    async ${serviceName}sCount(parent, { filter }, context: GraphQLContext) {
      return await context.services.${serviceName}.count(filter);
    }
  },

  Mutation: {
    // Create ${table.label}
    async create${typeName}(parent, { input }, context: GraphQLContext) {
      // Validate input
      await context.validate(input, '${typeName}Input');

      // Create
      return await context.services.${serviceName}.create(input);
    },

    // Update ${table.label}
    async update${typeName}(parent, { id, input }, context: GraphQLContext) {
      // Validate input
      await context.validate(input, '${typeName}UpdateInput');

      // Check exists
      const exists = await context.services.${serviceName}.findById(id);
      if (!exists) {
        throw new Error('${typeName} not found');
      }

      // Update
      return await context.services.${serviceName}.update(id, input);
    },

    // Delete ${table.label}
    async delete${typeName}(parent, { id }, context: GraphQLContext) {
      // Check exists
      const exists = await context.services.${serviceName}.findById(id);
      if (!exists) {
        throw new Error('${typeName} not found');
      }

      // Delete
      return await context.services.${serviceName}.delete(id);
    }
  },

  ${typeName}: {
${this.generateFieldResolvers(table)}
  }
};
    `.trim();
  }

  private generateFieldResolvers(table: TableMetadata): string {
    const resolvers: string[] = [];

    // Relation resolvers
    const relations = table.relations || [];
    for (const rel of relations) {
      const targetService = this.toCamelCase(rel.toTable);
      const isArray = rel.relationType.includes('Many');

      if (isArray) {
        resolvers.push(`
    // ${rel.graphqlField}: OneToMany or ManyToMany
    async ${rel.graphqlField}(parent, args, context: GraphQLContext) {
      return await context.loaders.${targetService}By${this.toPascalCase(rel.fromColumn)}.load(parent.id);
    }`);
      } else {
        resolvers.push(`
    // ${rel.graphqlField}: ManyToOne or OneToOne
    async ${rel.graphqlField}(parent, args, context: GraphQLContext) {
      if (!parent.${rel.fromColumn}) return null;
      return await context.loaders.${targetService}ById.load(parent.${rel.fromColumn});
    }`);
      }
    }

    return resolvers.join('\n');
  }

  private generateMergedResolvers(tables: TableMetadata[]): string {
    const resolverNames = tables
      .filter(t => t.isApiEnabled)
      .map(t => `${this.toCamelCase(t.tableName)}Resolvers`)
      .join(',\n  ');

    return `
/**
 * Merged resolvers
 */
export const resolvers: Resolvers = {
  Query: {
${tables.filter(t => t.isApiEnabled).map(t => {
  const serviceName = this.toCamelCase(t.tableName);
  return `    ...${serviceName}Resolvers.Query,`;
}).join('\n')}
  },

  Mutation: {
${tables.filter(t => t.isApiEnabled).map(t => {
  const serviceName = this.toCamelCase(t.tableName);
  return `    ...${serviceName}Resolvers.Mutation,`;
}).join('\n')}
  },

${tables.filter(t => t.isApiEnabled).map(t => {
  const typeName = this.toPascalCase(t.tableName);
  const serviceName = this.toCamelCase(t.tableName);
  return `  ${typeName}: ${serviceName}Resolvers.${typeName},`;
}).join('\n')}
};
    `.trim();
  }
}
```

---

## React Form Generator

```typescript
// generators/react-form-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata, ColumnMetadata } from '../types/metadata';
import fs from 'fs/promises';
import path from 'path';

export class ReactFormGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<void> {
    for (const table of tables) {
      const formCode = await this.generateForm(table);
      const outputPath = path.join(
        process.cwd(),
        'frontend/src/generated/forms',
        `${table.tableName}-form.tsx`
      );

      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      await fs.writeFile(outputPath, formCode);
    }
  }

  private async generateForm(table: TableMetadata): Promise<string> {
    const header = this.generateFileHeader(`${table.label} Form Component`);
    const typeName = this.toPascalCase(table.tableName);
    const imports = this.generateFormImports(table);
    const schema = this.generateZodSchema(table);
    const component = this.generateFormComponent(table);

    const code = `
${header}

${imports}

${schema}

${component}
    `.trim();

    return this.formatCode(code, 'typescript');
  }

  private generateFormImports(table: TableMetadata): string {
    const hasSelect = table.columns.some(c => c.formType === 'select');
    const hasTextarea = table.columns.some(c => c.formType === 'textarea');
    const hasCheckbox = table.columns.some(c => c.formType === 'checkbox');
    const hasDate = table.columns.some(c => ['date', 'datetime'].includes(c.formType));

    return `
import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';

import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
${hasSelect ? "import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';" : ''}
${hasTextarea ? "import { Textarea } from '@/components/ui/textarea';" : ''}
${hasCheckbox ? "import { Checkbox } from '@/components/ui/checkbox';" : ''}
${hasDate ? "import { DatePicker } from '@/components/ui/date-picker';" : ''}
    `.trim();
  }

  private generateZodSchema(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);
    const schemaName = `${this.toCamelCase(table.tableName)}Schema`;

    const fields = table.columns
      .filter(c => c.isVisible && !c.isPrimaryKey)
      .map(c => this.generateZodField(c))
      .join(',\n  ');

    return `
// Zod validation schema
const ${schemaName} = z.object({
  ${fields}
});

export type ${typeName}FormValues = z.infer<typeof ${schemaName}>;
    `.trim();
  }

  private generateZodField(column: ColumnMetadata): string {
    const validation = column.validationRules || {};
    let zodType = '';

    // Base type
    switch (column.graphqlType) {
      case 'String':
        zodType = 'z.string()';
        if (validation.minLength) zodType += `.min(${validation.minLength}, '최소 ${validation.minLength}자 이상 입력하세요')`;
        if (validation.maxLength) zodType += `.max(${validation.maxLength}, '최대 ${validation.maxLength}자까지 입력 가능합니다')`;
        if (validation.pattern) zodType += `.regex(/${validation.pattern}/, '올바른 형식이 아닙니다')`;
        if (column.formType === 'email') zodType += `.email('올바른 이메일 형식이 아닙니다')`;
        break;

      case 'Int':
      case 'Float':
        zodType = 'z.number()';
        if (validation.min !== undefined) zodType += `.min(${validation.min})`;
        if (validation.max !== undefined) zodType += `.max(${validation.max})`;
        break;

      case 'Boolean':
        zodType = 'z.boolean()';
        break;

      case 'DateTime':
        zodType = 'z.date()';
        break;

      default:
        if (column.enumOptions) {
          const values = column.enumOptions.map((o: any) => `'${o.value}'`).join(', ');
          zodType = `z.enum([${values}])`;
        } else {
          zodType = 'z.string()';
        }
    }

    // Optional
    if (!column.isRequired) {
      zodType += '.optional()';
    }

    return `${column.graphqlField}: ${zodType}`;
  }

  private generateFormComponent(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);
    const schemaName = `${this.toCamelCase(table.tableName)}Schema`;
    const fields = table.columns
      .filter(c => c.isVisible && !c.isPrimaryKey)
      .map(c => this.generateFormField(c))
      .join('\n\n');

    return `
export interface ${typeName}FormProps {
  initialData?: Partial<${typeName}FormValues>;
  onSubmit: (data: ${typeName}FormValues) => void | Promise<void>;
  loading?: boolean;
}

export const ${typeName}Form: React.FC<${typeName}FormProps> = ({
  initialData,
  onSubmit,
  loading = false
}) => {
  const form = useForm<${typeName}FormValues>({
    resolver: zodResolver(${schemaName}),
    defaultValues: initialData || {}
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        ${fields}

        <Button type="submit" disabled={loading}>
          {loading ? '저장 중...' : '저장'}
        </Button>
      </form>
    </Form>
  );
};
    `.trim();
  }

  private generateFormField(column: ColumnMetadata): string {
    const required = column.isRequired ? ' *' : '';

    switch (column.formType) {
      case 'text':
      case 'email':
      case 'password':
      case 'number':
        return `
        <FormField
          control={form.control}
          name="${column.graphqlField}"
          render={({ field }) => (
            <FormItem>
              <FormLabel>${column.label}${required}</FormLabel>
              <FormControl>
                <Input
                  {...field}
                  type="${column.formType}"
                  placeholder="${column.placeholder || ''}"
                  disabled={loading}
                />
              </FormControl>
              ${column.helpText ? `<FormDescription>${column.helpText}</FormDescription>` : ''}
              <FormMessage />
            </FormItem>
          )}
        />`;

      case 'textarea':
        return `
        <FormField
          control={form.control}
          name="${column.graphqlField}"
          render={({ field }) => (
            <FormItem>
              <FormLabel>${column.label}${required}</FormLabel>
              <FormControl>
                <Textarea
                  {...field}
                  placeholder="${column.placeholder || ''}"
                  disabled={loading}
                  rows={4}
                />
              </FormControl>
              ${column.helpText ? `<FormDescription>${column.helpText}</FormDescription>` : ''}
              <FormMessage />
            </FormItem>
          )}
        />`;

      case 'select':
        const options = column.enumOptions?.map((opt: any) =>
          `<SelectItem value="${opt.value}">${opt.label}</SelectItem>`
        ).join('\n                  ') || '';

        return `
        <FormField
          control={form.control}
          name="${column.graphqlField}"
          render={({ field }) => (
            <FormItem>
              <FormLabel>${column.label}${required}</FormLabel>
              <Select
                onValueChange={field.onChange}
                defaultValue={field.value}
                disabled={loading}
              >
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="${column.placeholder || '선택하세요'}" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  ${options}
                </SelectContent>
              </Select>
              ${column.helpText ? `<FormDescription>${column.helpText}</FormDescription>` : ''}
              <FormMessage />
            </FormItem>
          )}
        />`;

      case 'checkbox':
        return `
        <FormField
          control={form.control}
          name="${column.graphqlField}"
          render={({ field }) => (
            <FormItem className="flex flex-row items-start space-x-3 space-y-0">
              <FormControl>
                <Checkbox
                  checked={field.value}
                  onCheckedChange={field.onChange}
                  disabled={loading}
                />
              </FormControl>
              <div className="space-y-1 leading-none">
                <FormLabel>${column.label}</FormLabel>
                ${column.helpText ? `<FormDescription>${column.helpText}</FormDescription>` : ''}
              </div>
            </FormItem>
          )}
        />`;

      default:
        return `<!-- Unsupported field type: ${column.formType} -->`;
    }
  }
}
```

---

## React Table Generator

```typescript
// generators/react-table-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata } from '../types/metadata';
import fs from 'fs/promises';
import path from 'path';

export class ReactTableGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<void> {
    for (const table of tables) {
      const tableCode = await this.generateTable(table);
      const outputPath = path.join(
        process.cwd(),
        'frontend/src/generated/tables',
        `${table.tableName}-table.tsx`
      );

      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      await fs.writeFile(outputPath, tableCode);
    }
  }

  private async generateTable(table: TableMetadata): Promise<string> {
    const header = this.generateFileHeader(`${table.label} Table Component`);
    const typeName = this.toPascalCase(table.tableName);
    const imports = this.generateTableImports();
    const columns = this.generateColumns(table);
    const component = this.generateTableComponent(table);

    const code = `
${header}

${imports}

${columns}

${component}
    `.trim();

    return this.formatCode(code, 'typescript');
  }

  private generateTableImports(): string {
    return `
import React from 'react';
import { ColumnDef } from '@tanstack/react-table';
import { DataTable } from '@/components/ui/data-table';
import { Badge } from '@/components/ui/badge';
import { format } from 'date-fns';
    `.trim();
  }

  private generateColumns(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);
    const visibleColumns = table.columns.filter(c => c.isVisible);

    const columnDefs = visibleColumns.map(col => {
      return this.generateColumnDef(col);
    }).join(',\n  ');

    return `
const columns: ColumnDef<${typeName}>[] = [
  ${columnDefs}
];
    `.trim();
  }

  private generateColumnDef(column: ColumnMetadata): string {
    let columnDef = `{
    accessorKey: '${column.graphqlField}',
    header: '${column.label}',
    enableSorting: ${column.isSortable},
    enableColumnFilter: ${column.isFilterable}`;

    // Custom cell renderer for specific types
    if (column.enumOptions) {
      const statusMap = column.enumOptions.map((opt: any) =>
        `${opt.value}: { label: '${opt.label}', variant: 'default' as const }`
      ).join(',\n      ');

      columnDef += `,
    cell: ({ row }) => {
      const status = row.getValue('${column.graphqlField}') as string;
      const statusMap = {
        ${statusMap}
      };
      const { label, variant } = statusMap[status] || { label: status, variant: 'default' as const };
      return <Badge variant={variant}>{label}</Badge>;
    }`;
    } else if (column.graphqlType === 'DateTime') {
      columnDef += `,
    cell: ({ row }) => {
      const date = row.getValue('${column.graphqlField}') as Date;
      return format(new Date(date), 'yyyy-MM-dd HH:mm');
    }`;
    } else if (column.graphqlType === 'Boolean') {
      columnDef += `,
    cell: ({ row }) => {
      const value = row.getValue('${column.graphqlField}') as boolean;
      return <Badge variant={value ? 'success' : 'secondary'}>{value ? '예' : '아니오'}</Badge>;
    }`;
    }

    columnDef += '\n  }';
    return columnDef;
  }

  private generateTableComponent(table: TableMetadata): string {
    const typeName = this.toPascalCase(table.tableName);
    const searchableColumns = table.columns
      .filter(c => c.isSearchable)
      .map(c => `'${c.graphqlField}'`)
      .join(', ');

    const filterableEnums = table.columns
      .filter(c => c.isFilterable && c.enumOptions)
      .map(c => {
        const options = c.enumOptions!.map((opt: any) =>
          `{ label: '${opt.label}', value: '${opt.value}' }`
        ).join(', ');

        return `{
          id: '${c.graphqlField}',
          title: '${c.label}',
          options: [${options}]
        }`;
      })
      .join(',\n        ');

    return `
export interface ${typeName}TableProps {
  data: ${typeName}[];
  loading?: boolean;
  onRowClick?: (row: ${typeName}) => void;
}

export const ${typeName}Table: React.FC<${typeName}TableProps> = ({
  data,
  loading = false,
  onRowClick
}) => {
  return (
    <DataTable
      columns={columns}
      data={data}
      loading={loading}
      onRowClick={onRowClick}
      ${searchableColumns ? `searchableColumns={[${searchableColumns}]}` : ''}
      ${filterableEnums ? `filterableColumns={[\n        ${filterableEnums}\n      ]}` : ''}
    />
  );
};
    `.trim();
  }
}
```

---

## Migration Generator

```typescript
// generators/migration-generator.ts

import { BaseGenerator } from './base-generator';
import type { TableMetadata } from '../types/metadata';
import { execSync } from 'child_process';

export class MigrationGenerator extends BaseGenerator {
  async generate(tables: TableMetadata[]): Promise<string> {
    // 현재 DB 스키마 조회
    const currentSchema = await this.introspectDatabase();

    // 메타데이터 기반 원하는 스키마
    const desiredSchema = this.buildDesiredSchema(tables);

    // Diff 계산
    const diff = this.calculateDiff(currentSchema, desiredSchema);

    // Migration SQL 생성
    const migration = this.generateMigrationSQL(diff);

    return migration;
  }

  private async introspectDatabase(): Promise<any> {
    // PostgreSQL에서 현재 스키마 정보 조회
    const query = `
      SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable,
        c.column_default
      FROM information_schema.columns c
      WHERE c.table_schema = 'public'
      ORDER BY c.table_name, c.ordinal_position;
    `;

    // Execute query and return results
    // (실제 구현에서는 DB 연결 사용)
    return [];
  }

  private buildDesiredSchema(tables: TableMetadata[]): any {
    return tables.map(table => ({
      tableName: table.tableName,
      columns: table.columns.map(col => ({
        name: col.pgColumn,
        type: col.pgType,
        nullable: !col.isRequired,
        default: col.defaultValue
      }))
    }));
  }

  private calculateDiff(current: any, desired: any): any {
    const diff = {
      tablesToCreate: [],
      tablesToDrop: [],
      columnsToAdd: [],
      columnsToModify: [],
      columnsToDrop: []
    };

    // Diff 계산 로직
    // ...

    return diff;
  }

  private generateMigrationSQL(diff: any): string {
    const timestamp = Date.now();
    const parts: string[] = [];

    parts.push(`-- Migration: ${timestamp}`);
    parts.push(`-- Generated: ${new Date().toISOString()}\n`);

    // CREATE TABLE
    for (const table of diff.tablesToCreate) {
      parts.push(this.generateCreateTable(table));
    }

    // ALTER TABLE ADD COLUMN
    for (const column of diff.columnsToAdd) {
      parts.push(`ALTER TABLE ${column.tableName} ADD COLUMN ${column.definition};`);
    }

    // ALTER TABLE ALTER COLUMN
    for (const column of diff.columnsToModify) {
      parts.push(`ALTER TABLE ${column.tableName} ALTER COLUMN ${column.name} TYPE ${column.newType};`);
    }

    // ALTER TABLE DROP COLUMN
    for (const column of diff.columnsToDrop) {
      parts.push(`ALTER TABLE ${column.tableName} DROP COLUMN ${column.name};`);
    }

    // DROP TABLE
    for (const table of diff.tablesToDrop) {
      parts.push(`DROP TABLE IF EXISTS ${table.name} CASCADE;`);
    }

    return parts.join('\n\n');
  }

  private generateCreateTable(table: any): string {
    // CREATE TABLE DDL 생성
    return `CREATE TABLE ${table.name} (...);`;
  }
}
```

---

**문서 버전**: 1.0.0
**최종 수정**: 2024-10-19
**관리**: `/var/services/homes/jungsam/dev/dockers/_templates/docker/docker-ubuntu/_docs/guidelines/meta-data-driven`
