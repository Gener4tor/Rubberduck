﻿using Antlr4.Runtime;
using Rubberduck.Parsing.Annotations;
using Rubberduck.Parsing.ComReflection;
using Rubberduck.Parsing.VBA;
using Rubberduck.VBEditor;
using System.Collections.Generic;
using System.Linq;
using static Rubberduck.Parsing.Grammar.VBAParser;

namespace Rubberduck.Parsing.Symbols
{
    public sealed class FunctionDeclaration : ModuleBodyElementDeclaration
    {
        public FunctionDeclaration(
            QualifiedMemberName name,
            Declaration parent,
            Declaration parentScope,
            string asTypeName,
            AsTypeClauseContext asTypeContext,
            string typeHint,
            Accessibility accessibility,
            ParserRuleContext context,
            ParserRuleContext attributesPassContext,
            Selection selection,
            bool isArray,
            bool isUserDefined,
            IEnumerable<IAnnotation> annotations,
            Attributes attributes)
            : base(
                name,
                parent,
                parentScope,
                asTypeName,
                asTypeContext,
                typeHint,
                accessibility,
                DeclarationType.Function,
                context,
                attributesPassContext,
                selection,
                isArray,               
                isUserDefined,
                annotations,
                attributes)
        { }

        public FunctionDeclaration(ComMember member, Declaration parent, QualifiedModuleName module, Attributes attributes) 
            : this(
                module.QualifyMemberName(member.Name),
                parent,
                parent,
                member.AsTypeName.TypeName,
                null,
                null,
                Accessibility.Global,
                null,
                null,
                Selection.Home,
                member.AsTypeName.IsArray,
                false,
                null,
                attributes)
        {
            AddParameters(member.Parameters.Select(decl => new ParameterDeclaration(decl, this, module)));
        }

        /// <inheritdoc/>
        protected override bool Implements(IInterfaceExposable member)
        {
            if (ReferenceEquals(member, this))
            {
                return false;
            }

            return member.DeclarationType == DeclarationType.Function
                && member.IsInterfaceMember
                && IdentifierName.Equals(member.ImplementingIdentifierName)
                   && ((ClassModuleDeclaration)member.ParentDeclaration).Subtypes.Any(implementation => ReferenceEquals(implementation, ParentDeclaration));
        }

        public override BlockContext Block => ((FunctionStmtContext)Context).block();
    }
}
