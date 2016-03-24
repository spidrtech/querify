require 'test_helper'

describe ActiveRecord::Querify do

	before do
		truncate_db
	end

	describe 'Expressions' do

		describe 'without arguments' do

			before do

				@statement = "CASE WHEN posts.comments_count > 2 THEN 'Popular' ELSE 'Not Popular' END"

				# Create posts
				@post1 = FactoryGirl.create :post
				@post2 = FactoryGirl.create :post
				@post3 = FactoryGirl.create :post

				# Create comments
				4.times do
					FactoryGirl.create :comment, post: @post1
				end
				3.times do
					FactoryGirl.create :comment, post: @post3
				end

				@expr = ActiveRecord::Querify::Expression.new :popularity do |*args|
					@statement
				end

				@popular = ActiveRecord::Querify::Filter.new @expr, :eq, 'Popular', :string
				@not_popular = ActiveRecord::Querify::Filter.new @expr, :eq, 'Not Popular', :string

				@sort = ActiveRecord::Querify::Sort.new @expr, :asc

			end

			it 'should filter properly' do
				assert_equal [@post1, @post3], Post.where(*@popular.to_a).order(:id)
				assert_equal [@post2], Post.where(*@not_popular.to_a).order(:id)
			end

			it 'should assume the expression is always quoted in filters' do
				assert_equal @popular.column, @statement
				assert_equal @popular.column, @popular.quoted_column
			end

			it 'should assume the expression is always quoted when sorting' do
				assert_equal @sort.column, @statement
				assert_equal @sort.column, @sort.quoted_column
			end

			it 'should generate a proper query string representation' do

				assert_equal "where[:popularity][:eq]=Popular", @popular.to_s

			end

		end

		describe 'with arguments' do

			before do

				@statement = "CASE WHEN posts.comments_count > ? THEN ? ELSE ? END"
				@args = [3, 'Popular', 'Not Popular']

				# Create posts
				@post1 = FactoryGirl.create :post
				@post2 = FactoryGirl.create :post
				@post3 = FactoryGirl.create :post

				# Create comments
				4.times do
					FactoryGirl.create :comment, post: @post1
				end
				3.times do
					FactoryGirl.create :comment, post: @post3
				end

				@expr = ActiveRecord::Querify::Expression.new :popularity do |*args|
					[@statement, args[0].to_i, args[1].to_s, args[2].to_s]
				end

				# Set up the expression's arguments
				@expr.using *@args

				@popular = ActiveRecord::Querify::Filter.new @expr, :eq, 'Popular', :string
				@not_popular = ActiveRecord::Querify::Filter.new @expr, :eq, 'Not Popular', :string

				@sort = ActiveRecord::Querify::Sort.new @expr, :asc

			end

			it 'should pass arguments through Filter#to_a' do
				# Emulate the equals operation
				assert_equal [@statement + " = ?", *@args, "Popular"], @popular.to_a
			end

			it 'should filter with args properly' do

				@expr.using 3, "Popular", "Not Popular"
				assert_equal [@post1], Post.where(*@popular.to_a).order(:id)
				assert_equal [@post2, @post3], Post.where(*@not_popular.to_a).order(:id)

				@expr.using 5, "Popular", "Not Popular"
				assert_equal [@post1, @post2, @post3], Post.where(*@not_popular.to_a).order(:id)

			end

			it 'should assume the expression is always quoted in filters' do
				assert_equal @popular.column, @statement
				assert_equal @popular.column, @popular.quoted_column
			end

			it 'should assume the expression is always quoted when sorting' do
				assert_equal @sort.column, @statement
				assert_equal @sort.column, @sort.quoted_column
			end

			it 'should generate a proper query string representation' do

				@expr.using 2, "Foo", "Bar"
				assert_equal "where[:popularity][2][Foo][Bar][:eq]=Popular", @popular.to_s

				@expr.using 3, "Popular", "Not Popular"
				assert_equal "where[:popularity][3][Popular][Not+Popular][:eq]=Popular", @popular.to_s

			end

		end

	end

end
