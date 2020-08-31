defmodule CommonsPub.Emails.Email do

  use Pointers.Mixin,
    otp_app: :cpub_emails,
    source: "cpub_emails_email"

  alias Pointers.Changesets
  require Pointers.Changesets
  alias CommonsPub.Emails.Email
  alias Ecto.Changeset
  
  mixin_schema do
    field :email, :string
  end

  @defaults [
    cast:     [:email],
    required: [:email],
    email: [ format: ~r(^[^@]{1,128}@[^@\.]+.[^@]{2,128}$) ],
  ]

  def changeset(email \\ %Email{}, attrs, opts \\ []) do
    Changesets.auto(email, attrs, opts, @defaults)
    |> Changeset.unique_constraint(:email)
  end

end
defmodule CommonsPub.Emails.Email.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias CommonsPub.Emails.Email

  @email_table Email.__schema__(:source)

  def migrate_email(index_opts \\ [], dir \\ direction())

  def migrate_email(index_opts, :up) do
    create_mixin_table(Email) do
      add :email, :text
    end
    create_if_not_exists(unique_index(@email_table, [:email], index_opts))
  end

  def migrate_email(index_opts, :down) do
    drop_if_exists(unique_index(@email_table, [:username], index_opts))
    drop_mixin_table(Email)
  end

end
